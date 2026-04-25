import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/youtube_service.dart';
import '../library/library_models.dart';
import '../library/library_notifier.dart';
import '../playback/playback_notifier.dart';
import '../playback/playback_state.dart';
import '../settings/app_preferences.dart';
import 'artwork_service.dart';
import 'lastfm_service.dart';
import 'recommendation_models.dart';
import 'recommendation_preferences.dart';
import 'recommendation_state.dart';

/// Tracks enqueued via the recommendation engine use this prefix as their
/// synthetic `videoId`, mirroring the pattern used for Spotify playlist
/// imports. The real YouTube URL is resolved lazily when each track plays.
const String lastFmRecIdPrefix = 'lastfm_rec_';

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  RecommendationNotifier({
    required LastFmService lastFmService,
    required ArtworkService artworkService,
    required YoutubeService youtubeService,
    required LibraryNotifier libraryNotifier,
    required PlaybackNotifier playbackNotifier,
    required RecommendationPreferences Function() preferencesResolver,
    required Future<void> Function() ensurePreferencesLoaded,
  })  : _lastFm = lastFmService,
        _artwork = artworkService,
        _youtubeService = youtubeService,
        _libraryNotifier = libraryNotifier,
        _playbackNotifier = playbackNotifier,
        _preferencesResolver = preferencesResolver,
        _ensurePreferencesLoaded = ensurePreferencesLoaded,
        super(const RecommendationState());

  final LastFmService _lastFm;
  final ArtworkService _artwork;
  final YoutubeService _youtubeService;
  final LibraryNotifier _libraryNotifier;
  final PlaybackNotifier _playbackNotifier;
  final RecommendationPreferences Function() _preferencesResolver;
  final Future<void> Function() _ensurePreferencesLoaded;

  static const int _targetQueuedSongs = 30;
  static const int _initialQueuedSongs = 31;
  static const int _topUpThreshold = 12;
  static const int _tracksPerSeed = 5;
  static const int _parallelSeedBatchSize = 4;

  final Set<String> _seen = {};
  final Set<String> _enqueuedRecIds = {};
  List<LibraryTrack> _seedPool = const [];
  int _seedIndex = 0;
  int _sessionSeed = 0;
  int _enqueueCounter = 0;
  String? _initialTrackId;

  /// Entry point: called when the user presses Shuffle with an empty queue
  /// and nothing already playing. Seeds the queue with ~30 similar tracks.
  Future<void> startShuffle() async {
    if (state.isFetching) return;

    // Make sure saved preferences (API key, seed strategy) have been read
    // from disk before we use them.
    await _ensurePreferencesLoaded();

    final prefs = _preferencesResolver();
    if (prefs.apiKey.isEmpty) {
      state = state.copyWith(
        active: false,
        errorMessage:
            'Add your Last.fm API key in Settings › Recommendations › Autoplay recommendations.',
      );
      return;
    }

    final seeds = _collectSeeds();
    if (seeds.isEmpty) {
      state = state.copyWith(
        active: false,
        errorMessage: _emptySeedMessage(),
      );
      return;
    }

    // Reset per-session state.
    _seen
      ..clear()
      ..addAll(_initialSeenKeys());
    _enqueuedRecIds.clear();
    _seedPool = seeds;
    _seedIndex = 0;
    _sessionSeed = DateTime.now().millisecondsSinceEpoch;
    _enqueueCounter = 0;
    _initialTrackId = _playbackNotifier.state.currentTrackId;

    state = state.copyWith(active: true, errorMessage: null);

    await _fetchUntilTarget();

    if (_playbackNotifier.state.queue.isEmpty) {
      // `_fetchUntilTarget` only sets `errorMessage` for hard failures
      // (missing API key, HTTP errors). An empty queue without one of
      // those means Last.fm just doesn't know this song/artist.
      state = state.copyWith(
        active: false,
        errorMessage: state.errorMessage ?? _noResultsMessage(seeds.first),
      );
      return;
    }

    // Kick off playback of the first recommendation only when nothing is
    // loaded at all.  When the user has a song paused or actively playing,
    // the recommendations should queue up behind it — not skip or resume
    // the current track.
    if (_playbackNotifier.state.currentTrackId == null) {
      await _playbackNotifier.nextTrack();
    }
  }

  /// Invoked by the provider whenever the playback state changes. Handles
  /// auto-refill once the queue drains and deactivates the session if the
  /// user manually starts playing something else (e.g. a playlist).
  Future<void> handlePlaybackChange(PlaybackState playback) async {
    if (!state.active) return;

    final currentId = playback.currentTrackId;

    // Ignore transient states before our first rec actually starts playing.
    if (currentId == _initialTrackId) return;

    // If the user diverted to a non-recommendation track, hand control back.
    if (currentId == null || !_enqueuedRecIds.contains(currentId)) {
      stop();
      return;
    }

    if (playback.queue.length <= _topUpThreshold && !state.isFetching) {
      await _fetchUntilTarget();
    }
  }

  /// Explicitly disable the rec-shuffle session (without touching playback).
  void stop() {
    if (!state.active) return;
    state = state.copyWith(active: false);
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _fetchUntilTarget() async {
    if (state.isFetching) return;
    state = state.copyWith(isFetching: true);
    try {
      final refreshedSeeds = _collectSeeds();
      if (refreshedSeeds.isNotEmpty) _seedPool = refreshedSeeds;
      if (_seedPool.isEmpty) return;

      await _fetchLastFmRecommendations();
    } finally {
      state = state.copyWith(isFetching: false);
    }
  }

  Future<void> _fetchLastFmRecommendations() async {
    // How many similar tracks to request from Last.fm per seed.  When the
    // seed pool is small (e.g. "currently playing" = 1 seed), we ask for
    // a larger batch so a single pass can fill the queue.  With many seeds
    // we keep requests small so the mix stays varied.
    final queueTarget = _queueTarget();
    final limitPerSeed = _seedPool.length <= 3 ? queueTarget : _tracksPerSeed;
    final computedAttempts = ((queueTarget ~/ limitPerSeed) + 1) * 4;
    final maxAttempts = computedAttempts < 20 ? 20 : computedAttempts;
    var attempts = 0;
    var consecutiveEmpty = 0;
    const maxConsecutiveEmpty = 8;

    while (_playbackNotifier.state.queue.length < queueTarget &&
        attempts < maxAttempts) {
      final seeds = _nextSeedBatch();
      attempts += seeds.length;

      List<List<RecommendedTrack>> recBatches;
      try {
        recBatches = await Future.wait(
          seeds.map((seed) => _fetchRecommendationsForSeed(
                seed,
                limitPerSeed: limitPerSeed,
              )),
        );
      } on RecommendationException catch (error) {
        if (error.code == 'missing_api_key') break;
        continue;
      }
      final recs = recBatches.expand((batch) => batch).toList(growable: false);

      if (recs.isEmpty) {
        consecutiveEmpty++;
        if (consecutiveEmpty >= maxConsecutiveEmpty) break;
        continue;
      }
      consecutiveEmpty = 0;

      final hydratedRecs = await _hydratePreferredThumbnails(recs);

      final enqueuedPairs = <(String id, RecommendedTrack rec)>[];
      for (final rec in hydratedRecs) {
        if (_playbackNotifier.state.queue.length >= queueTarget) break;
        final key = rec.dedupKey;
        if (_seen.contains(key)) continue;
        _seen.add(key);
        final id = _enqueue(rec);
        if (id != null) enqueuedPairs.add((id, rec));
      }

      _enrichMissingThumbnailsInBackground(enqueuedPairs);
    }
  }

  int _queueTarget() {
    final currentId = _playbackNotifier.state.currentTrackId;
    final hasActiveTrack = currentId != null && currentId.isNotEmpty;
    return hasActiveTrack ? _targetQueuedSongs : _initialQueuedSongs;
  }

  List<LibraryTrack> _nextSeedBatch() {
    if (_seedPool.isEmpty) return const [];

    final batchSize = _seedPool.length < _parallelSeedBatchSize
        ? _seedPool.length
        : _parallelSeedBatchSize;

    return List<LibraryTrack>.generate(batchSize, (_) => _nextSeed());
  }

  Future<List<RecommendedTrack>> _fetchRecommendationsForSeed(
    LibraryTrack seed, {
    required int limitPerSeed,
  }) async {
    List<RecommendedTrack> lastFmTracks;
    try {
      lastFmTracks = await _lastFm.getSimilarTracks(
        artist: seed.artist,
        title: seed.title,
        limit: limitPerSeed,
      );
    } on RecommendationException catch (error) {
      state = state.copyWith(errorMessage: error.message);
      if (error.code == 'missing_api_key') rethrow;
      lastFmTracks = const [];
    }

    if (lastFmTracks.length >= limitPerSeed) {
      return lastFmTracks;
    }

    final youtubeFallback = await _fetchYoutubeFallbackRecommendations(
      seed,
      limit: limitPerSeed,
      exclude: lastFmTracks,
    );
    if (youtubeFallback.isEmpty) return lastFmTracks;

    final merged = <RecommendedTrack>[];
    final seen = <String>{};
    for (final track in [...lastFmTracks, ...youtubeFallback]) {
      if (seen.add(track.dedupKey)) {
        merged.add(track);
      }
      if (merged.length >= limitPerSeed) break;
    }
    return merged;
  }

  Future<List<RecommendedTrack>> _fetchYoutubeFallbackRecommendations(
    LibraryTrack seed, {
    required int limit,
    required List<RecommendedTrack> exclude,
  }) async {
    try {
      final results = await _fetchYoutubeFallbackCandidates(seed);
      if (results.isEmpty) return const [];
      final autoplayCandidates = YoutubeService.rankAutoplayCandidates(
        results,
        maxDuration: YoutubeService.maxRecommendationDuration,
      );
      if (autoplayCandidates.isEmpty) return const [];

      final blocked = {
        ...exclude.map((track) => track.dedupKey),
        RecommendedTrack.dedupKeyFor(
          artist: seed.artist,
          title: seed.title,
        ),
      };

      final out = <RecommendedTrack>[];
      for (final result in autoplayCandidates) {
        final rec = RecommendedTrack.fromYoutubeSearchItem(
          result,
          fallbackArtist: seed.artist,
        );
        final title = rec.title.trim();
        final artist = rec.artist.trim();
        if (title.isEmpty || artist.isEmpty) continue;
        if (_looksLikeSeedVariant(rec, seed)) continue;

        if (!blocked.add(rec.dedupKey)) continue;

        out.add(rec.copyWith(
          imageUrl: _sanitizeAllowedThumbnail(result.thumbnailUrl),
        ));
        if (out.length >= limit) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<List<YoutubeSearchItem>> _fetchYoutubeFallbackCandidates(
    LibraryTrack seed,
  ) async {
    final queries = <String>[
      '${seed.artist} songs',
      '${seed.artist} topic',
      seed.artist,
    ];

    final merged = <YoutubeSearchItem>[];
    final seenIds = <String>{};
    for (final query in queries) {
      try {
        final results = await _youtubeService.search(query);
        for (final result in results) {
          if (seenIds.add(result.id)) merged.add(result);
        }
      } catch (_) {
        continue;
      }
    }
    return merged;
  }

  bool _looksLikeSeedVariant(RecommendedTrack candidate, LibraryTrack seed) {
    final seedKey = RecommendedTrack.dedupKeyFor(
      artist: seed.artist,
      title: seed.title,
    );
    if (candidate.dedupKey == seedKey) return true;

    final seedTitle = RecommendedTrack.normalizedTitleFor(seed.title);
    final candidateTitle = RecommendedTrack.normalizedTitleFor(candidate.title);
    if (seedTitle.isEmpty || candidateTitle.isEmpty) return false;

    if (candidateTitle.contains(seedTitle) ||
        seedTitle.contains(candidateTitle)) {
      return true;
    }

    final seedTokens =
        seedTitle.split(' ').where((part) => part.isNotEmpty).toSet();
    final candidateTokens =
        candidateTitle.split(' ').where((part) => part.isNotEmpty).toSet();
    if (seedTokens.isEmpty || candidateTokens.isEmpty) return false;

    final overlap = seedTokens.intersection(candidateTokens).length;
    final minSize = seedTokens.length < candidateTokens.length
        ? seedTokens.length
        : candidateTokens.length;
    return minSize > 0 && overlap >= minSize;
  }

  LibraryTrack _nextSeed() {
    final seed = _seedPool[_seedIndex % _seedPool.length];
    _seedIndex++;
    return seed;
  }

  /// Enqueues a recommended track and returns the generated ID, or null if
  /// the track was already in the queue.
  String? _enqueue(RecommendedTrack rec) {
    final recKey = rec.dedupKey;
    final playback = _playbackNotifier.state;
    final currentTitle = playback.currentTitle?.trim() ?? '';
    final currentArtist = playback.currentArtist?.trim() ?? '';

    if (currentTitle.isNotEmpty &&
        currentArtist.isNotEmpty &&
        RecommendedTrack.dedupKeyFor(
              artist: currentArtist,
              title: currentTitle,
            ) ==
            recKey) {
      return null;
    }

    if (playback.queue.any(
      (track) =>
          RecommendedTrack.dedupKeyFor(
            artist: track.artist,
            title: track.title,
          ) ==
          recKey,
    )) {
      return null;
    }

    final id = '$lastFmRecIdPrefix${_sessionSeed}_${_enqueueCounter++}';
    final added = _playbackNotifier.addToQueue(
      videoId: id,
      videoUrl: '',
      title: rec.title,
      artist: rec.artist,
      thumbnailUrl: _sanitizeAllowedThumbnail(rec.imageUrl),
    );
    if (!added) return null;
    _enqueuedRecIds.add(id);
    return id;
  }

  Future<List<RecommendedTrack>> _hydratePreferredThumbnails(
    List<RecommendedTrack> recs,
  ) async {
    final urls = await Future.wait(
      recs.map(_resolvePreferredThumbnail),
    );

    return List<RecommendedTrack>.generate(recs.length, (index) {
      final url = urls[index];
      if (url.isEmpty) return recs[index];
      return recs[index].copyWith(imageUrl: url);
    }, growable: false);
  }

  /// Re-tries only unresolved thumbnails so queue rows rarely stay empty.
  void _enrichMissingThumbnailsInBackground(
    List<(String id, RecommendedTrack rec)> pairs,
  ) {
    for (final (id, rec) in pairs) {
      if (rec.imageUrl.isNotEmpty) continue;
      _resolvePreferredThumbnail(rec).then((url) {
        if (url.isNotEmpty && mounted) {
          _playbackNotifier.updateQueuedTrackThumbnail(id, url);
        }
      }).catchError((_) {/* best-effort */});
    }
  }

  Future<String> _resolvePreferredThumbnail(RecommendedTrack rec) async {
    final existing = _sanitizeAllowedThumbnail(rec.imageUrl);
    if (existing.isNotEmpty) return existing;

    final artwork = await _artwork.fetchArtwork(
      artist: rec.artist,
      title: rec.title,
    );
    final sanitizedArtwork = _sanitizeAllowedThumbnail(artwork);
    if (sanitizedArtwork.isNotEmpty) return sanitizedArtwork;

    try {
      final results =
          await _youtubeService.search('${rec.title} ${rec.artist}');
      final match = YoutubeService.selectAutoplayCandidate(
        results,
        title: rec.title,
        artist: rec.artist,
        maxDuration: YoutubeService.maxRecommendationDuration,
      );
      if (match == null) return '';
      return _sanitizeAllowedThumbnail(match.thumbnailUrl);
    } catch (_) {
      return '';
    }
  }

  String _sanitizeAllowedThumbnail(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    final uri = Uri.tryParse(trimmed);
    final host = uri?.host.toLowerCase() ?? '';

    if (host.contains('itunes.apple.com') ||
        host.contains('is1-ssl.mzstatic.com') ||
        host.contains('mzstatic.com') ||
        host.contains('i.ytimg.com') ||
        host.contains('ytimg.com') ||
        host.contains('img.youtube.com') ||
        host.contains('youtube.com') ||
        host.contains('youtube-nocookie.com') ||
        host.contains('scdn.co') ||
        host.contains('spotifycdn.com') ||
        host.contains('spotify.com')) {
      return trimmed;
    }

    return '';
  }

  /// Picks seeds based on the user's configured strategy. Library-based
  /// strategies fall back to whatever other pool is available so shuffle
  /// still works when the preferred source is empty (e.g. first run, no
  /// liked songs). The `currentlyPlaying` strategy intentionally does not
  /// fall back — if nothing is playing, the session fails with a message.
  List<LibraryTrack> _collectSeeds() {
    final prefs = _preferencesResolver();
    final strategy = prefs.seedStrategy;

    if (strategy == RecommendationSeedStrategy.currentlyPlaying) {
      final current = _currentlyPlayingAsSeed();
      return current != null ? [current] : const [];
    }

    final recent = _libraryNotifier.state.recentTracks
        .where((t) => t.title.trim().isNotEmpty && t.artist.trim().isNotEmpty)
        .toList(growable: false);
    final liked = _libraryNotifier.state.likedTracks
        .where((t) => t.title.trim().isNotEmpty && t.artist.trim().isNotEmpty)
        .toList(growable: false);

    switch (strategy) {
      case RecommendationSeedStrategy.mostRecent:
        return recent.isNotEmpty ? recent : liked;
      case RecommendationSeedStrategy.randomLiked:
        if (liked.isEmpty) return recent;
        final shuffled = List<LibraryTrack>.from(liked)..shuffle(Random());
        return shuffled;
      case RecommendationSeedStrategy.mixLikedRecent:
        return _interleave(liked, recent);
      case RecommendationSeedStrategy.currentlyPlaying:
        // Handled above; unreachable but keeps the switch exhaustive.
        return const [];
    }
  }

  String _emptySeedMessage() {
    return _preferencesResolver().seedStrategy ==
            RecommendationSeedStrategy.currentlyPlaying
        ? 'Play a song first, then tap shuffle to build a station from it.'
        : 'Play or like a few tracks first so we have something to shuffle from.';
  }

  /// Message shown when we have a valid seed but Last.fm returned nothing
  /// usable — even after the artist-level fallback. Regional catalogs
  /// (Hindi, K-pop, local indie) are the most common cause.
  String _noResultsMessage(LibraryTrack seed) {
    final strategy = _preferencesResolver().seedStrategy;
    final label = '"${seed.title}" by ${seed.artist}';
    if (strategy == RecommendationSeedStrategy.currentlyPlaying) {
      return "Last.fm doesn't know $label well enough to recommend similar songs. Try a different song, or switch the seed strategy.";
    }
    return "Last.fm didn't return anything for the tracks in your library. Try a different song, or switch the seed strategy.";
  }

  /// Builds a seed from the currently-playing track without touching liked
  /// songs or recent plays. Returns null when nothing is playing (or when
  /// title/artist are blank, which happens briefly while a track is being
  /// prepared).
  LibraryTrack? _currentlyPlayingAsSeed() {
    final playback = _playbackNotifier.state;
    final title = playback.currentTitle?.trim() ?? '';
    final artist = playback.currentArtist?.trim() ?? '';
    if (title.isEmpty || artist.isEmpty) return null;
    return LibraryTrack(
      videoId: playback.currentTrackId ?? '',
      videoUrl: playback.currentVideoUrl ?? '',
      title: title,
      artist: artist,
      durationSeconds: 0,
      thumbnailUrl: playback.currentThumbnailUrl ?? '',
      reaction: '',
    );
  }

  /// Round-robin interleave that keeps both sources represented early in the
  /// rotation — so even a small liked-songs list still influences the mix.
  List<LibraryTrack> _interleave(
    List<LibraryTrack> a,
    List<LibraryTrack> b,
  ) {
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    final seen = <String>{};
    final out = <LibraryTrack>[];
    final maxLen = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < maxLen; i++) {
      for (final src in [a, b]) {
        if (i < src.length && seen.add(src[i].videoId)) out.add(src[i]);
      }
    }
    return out;
  }

  /// Seed the dedup set with everything the user has already heard or liked,
  /// so recommendations focus on discovery rather than looping the library.
  Set<String> _initialSeenKeys() {
    final keys = <String>{};
    void addKey(String artist, String title) {
      final key = RecommendedTrack.dedupKeyFor(
        artist: artist,
        title: title,
      );
      if (key != '|') keys.add(key);
    }

    for (final t in _libraryNotifier.state.recentTracks) {
      addKey(t.artist, t.title);
    }
    for (final t in _libraryNotifier.state.likedTracks) {
      addKey(t.artist, t.title);
    }
    final playback = _playbackNotifier.state;
    if ((playback.currentArtist ?? '').trim().isNotEmpty &&
        (playback.currentTitle ?? '').trim().isNotEmpty) {
      addKey(playback.currentArtist!, playback.currentTitle!);
    }
    for (final t in playback.queue) {
      addKey(t.artist, t.title);
    }
    return keys;
  }
}
