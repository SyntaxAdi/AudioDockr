import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../library/library_provider.dart';
import '../recommendations/recommendation_preferences.dart';
import '../services/native_player_service.dart';
import '../settings/app_preferences.dart';
import '../api/jiosaavn_service.dart';
import '../api/youtube_service.dart';
import 'playback_engine_mixin.dart';
import 'playback_event_mixin.dart';
import 'playback_models.dart';
import 'playback_queue_mixin.dart';
import 'playback_state.dart';
import 'playback_url_resolver.dart';

abstract class PlaybackNotifierBase extends StateNotifier<PlaybackState> {
  PlaybackNotifierBase() : super(PlaybackState());

  NativePlayerService get nativePlayerService;
  LibraryNotifier get libraryNotifier;
  PlaybackUrlResolver get resolver;

  bool isAdvancingQueue = false;
  final List<QueuedTrack> history = [];
  DateTime? lastTrackStart;

  Future<void> playTrackInternal({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    String? localFilePath,
  });
  Future<void> advanceQueue();
  QueuedTrack? currentTrackSnapshot();
  Future<void> playNextQueuedTrack();
  Future<void> seek(Duration pos);
  void handleNativePlayerEvent(Map<String, dynamic> event);
  bool addToQueue({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    String? localFilePath,
  });
  void setShuffleEnabled(bool enabled);
  void clearQueue();
  void updateQueuedTrackThumbnail(String videoId, String thumbnailUrl);
  Future<void> nextTrack();
  Future<void> previousTrack();
  Future<void> toggleShuffleQueue();
}

class PlaybackNotifier extends PlaybackNotifierBase
    with PlaybackEngineMixin, PlaybackQueueMixin, PlaybackEventMixin {
  // ── Dependencies (accessible to mixins) ───────────────────────────────────

  @override
  final NativePlayerService nativePlayerService;
  @override
  final LibraryNotifier libraryNotifier;
  @override
  final PlaybackUrlResolver resolver;

  final RecommendationPreferences Function() _preferencesResolver;
  final Future<void> Function() _ensurePreferencesLoaded;
  final Future<void> Function() _startRecommendationSession;

  // ── Mutable mixin-shared state ────────────────────────────────────────────

  StreamSubscription<Map<String, dynamic>>? _playerEventsSubscription;
  bool _inPlayTracks = false;
  String? _restoredLocalFilePath;

  // ── Constructor ───────────────────────────────────────────────────────────

  PlaybackNotifier(
    this.nativePlayerService,
    YoutubeService youtubeService,
    JioSaavnService jiosaavnService,
    this.libraryNotifier, {
    required RecommendationPreferences Function() preferencesResolver,
    required Future<void> Function() ensurePreferencesLoaded,
    required Future<void> Function() startRecommendationSession,
  })  : _preferencesResolver = preferencesResolver,
        _ensurePreferencesLoaded = ensurePreferencesLoaded,
        _startRecommendationSession = startRecommendationSession,
        resolver = PlaybackUrlResolver(
          youtubeService: youtubeService,
          jiosaavnService: jiosaavnService,
          libraryNotifier: libraryNotifier,
        ),
        super() {
    _playerEventsSubscription =
        nativePlayerService.playerStateStream.listen(handleNativePlayerEvent);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> playTrack(
    String videoId,
    String videoUrl,
    String title,
    String artist,
    String thumbnailUrl, {
    String? localFilePath,
  }) async {
    // Auto-enable shuffle and start the recommendation session when the
    // user has a Last.fm API key configured and plays a single song
    // (not when called internally from playTracks).
    var shouldAutoShuffle = false;
    if (!_inPlayTracks && !state.shuffleEnabled) {
      await _ensurePreferencesLoaded();
      if (_preferencesResolver().apiKey.isNotEmpty) {
        shouldAutoShuffle = true;
        setShuffleEnabled(true);
      }
    }

    final current = currentTrackSnapshot();
    if (current != null && current.videoId != videoId) {
      history.add(current);
    }
    await playTrackInternal(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      localFilePath: localFilePath,
    );

    if (shouldAutoShuffle && state.shuffleEnabled) {
      unawaited(_startRecommendationSession());
    }
  }

  Future<void> playTracks(List<LibraryTrack> tracks, {bool? shuffle}) async {
    if (tracks.isEmpty) return;

    final shouldShuffle = shuffle ?? state.shuffleEnabled;
    final orderedTracks = List<LibraryTrack>.from(tracks);
    if (shouldShuffle) orderedTracks.shuffle(Random());

    final firstTrack = orderedTracks.first;
    history.clear();
    state = state.copyWith(
      shuffleEnabled: shouldShuffle,
      queue: orderedTracks
          .skip(1)
          .map((t) => QueuedTrack(
                videoId: t.videoId,
                videoUrl: t.videoUrl,
                title: t.title,
                artist: t.artist,
                thumbnailUrl: t.thumbnailUrl,
                localFilePath: t.localFilePath,
              ))
          .toList(growable: false),
    );

    _inPlayTracks = true;
    try {
      await playTrack(
        firstTrack.videoId,
        firstTrack.videoUrl,
        firstTrack.title,
        firstTrack.artist,
        firstTrack.thumbnailUrl,
        localFilePath: firstTrack.localFilePath,
      );
    } finally {
      _inPlayTracks = false;
    }
  }

  Future<void> togglePlayPause() async {
    if (state.isPreparing) return;

    if (state.isRestoredSession) {
      final savedPosition = state.restoredPosition ?? Duration.zero;
      final trackId = state.currentTrackId!;
      final videoUrl = state.currentVideoUrl ?? '';
      final title = state.currentTitle ?? '';
      final artist = state.currentArtist ?? '';
      final thumbnailUrl = state.currentThumbnailUrl ?? '';
      final localFilePath = _restoredLocalFilePath;
      state = state.copyWith(
        isRestoredSession: false,
        restoredPosition: null,
      );
      _restoredLocalFilePath = null;
      await playTrack(
        trackId,
        videoUrl,
        title,
        artist,
        thumbnailUrl,
        localFilePath: localFilePath,
      );
      if (savedPosition > Duration.zero) {
        await Future.delayed(const Duration(milliseconds: 800));
        await seek(savedPosition);
      }
      return;
    }

    if (state.isPlaying) {
      await nativePlayerService.pause();
    } else {
      await nativePlayerService.resume();
    }
  }

  Future<void> pauseAndDismissNotification() async {
    await nativePlayerService.dismissNotification();
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> saveSession() async {
    if (state.currentTrackId == null || state.isRestoredSession) return;
    final prefs = await SharedPreferences.getInstance();
    if (!AppPreferences.readResumeOnStart(prefs)) return;

    await prefs.setString(AppPreferences.sessionVideoIdKey, state.currentTrackId!);
    await prefs.setString(AppPreferences.sessionTitleKey, state.currentTitle ?? '');
    await prefs.setString(AppPreferences.sessionArtistKey, state.currentArtist ?? '');
    await prefs.setString(AppPreferences.sessionThumbnailUrlKey, state.currentThumbnailUrl ?? '');
    await prefs.setString(AppPreferences.sessionVideoUrlKey, state.currentVideoUrl ?? '');
    await prefs.setString(AppPreferences.sessionLocalFilePathKey, state.currentLocalFilePath ?? '');
    await prefs.setInt(AppPreferences.sessionPositionMsKey, state.position.inMilliseconds);
    await prefs.setBool(AppPreferences.sessionShuffleEnabledKey, state.shuffleEnabled);
    final queueJson = jsonEncode(state.queue.map((t) => t.toJson()).toList());
    await prefs.setString(AppPreferences.sessionQueueJsonKey, queueJson);
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!AppPreferences.readResumeOnStart(prefs)) return;
    final videoId = prefs.getString(AppPreferences.sessionVideoIdKey);
    if (videoId == null || videoId.isEmpty) return;

    final title = prefs.getString(AppPreferences.sessionTitleKey) ?? '';
    final artist = prefs.getString(AppPreferences.sessionArtistKey) ?? '';
    final thumbnailUrl = prefs.getString(AppPreferences.sessionThumbnailUrlKey) ?? '';
    final videoUrl = prefs.getString(AppPreferences.sessionVideoUrlKey) ?? '';
    final localFilePath = prefs.getString(AppPreferences.sessionLocalFilePathKey);
    final positionMs = prefs.getInt(AppPreferences.sessionPositionMsKey) ?? 0;
    final shuffleEnabled = prefs.getBool(AppPreferences.sessionShuffleEnabledKey) ?? false;

    List<QueuedTrack> queue = const [];
    final queueJson = prefs.getString(AppPreferences.sessionQueueJsonKey);
    if (queueJson != null && queueJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(queueJson) as List<dynamic>;
        queue = decoded
            .map((e) => QueuedTrack.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
      } catch (_) {}
    }

    _restoredLocalFilePath = (localFilePath != null && localFilePath.isNotEmpty)
        ? localFilePath
        : null;

    state = state.copyWith(
      currentTrackId: videoId,
      currentTitle: title,
      currentArtist: artist,
      currentThumbnailUrl: thumbnailUrl,
      currentVideoUrl: videoUrl,
      currentLocalFilePath: _restoredLocalFilePath,
      isPlaying: false,
      isPreparing: false,
      isRestoredSession: true,
      position: Duration(milliseconds: positionMs),
      restoredPosition: Duration(milliseconds: positionMs),
      shuffleEnabled: shuffleEnabled,
      queue: queue,
    );
  }

  Future<void> clearSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppPreferences.sessionVideoIdKey);
    await prefs.remove(AppPreferences.sessionTitleKey);
    await prefs.remove(AppPreferences.sessionArtistKey);
    await prefs.remove(AppPreferences.sessionThumbnailUrlKey);
    await prefs.remove(AppPreferences.sessionVideoUrlKey);
    await prefs.remove(AppPreferences.sessionLocalFilePathKey);
    await prefs.remove(AppPreferences.sessionPositionMsKey);
    await prefs.remove(AppPreferences.sessionQueueJsonKey);
    await prefs.remove(AppPreferences.sessionShuffleEnabledKey);
  }

  @override
  Future<void> seek(Duration pos) async {
    await nativePlayerService.seekTo(pos.inMilliseconds);
  }

  Future<void> cycleRepeatMode() async {
    final nextMode = switch (state.repeatMode) {
      PlaybackRepeatMode.off => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.off,
    };

    await nativePlayerService.setRepeatMode(switch (nextMode) {
      PlaybackRepeatMode.off => 'off',
      PlaybackRepeatMode.one => 'one',
      PlaybackRepeatMode.all => 'all',
    });

    state = state.copyWith(repeatMode: nextMode);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _playerEventsSubscription?.cancel();
    super.dispose();
  }
}
