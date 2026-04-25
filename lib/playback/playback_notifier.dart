import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/library_provider.dart';
import '../recommendations/recommendation_preferences.dart';
import '../services/native_player_service.dart';
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

  // ── Constructor ───────────────────────────────────────────────────────────

  PlaybackNotifier(
    this.nativePlayerService,
    YoutubeService youtubeService,
    this.libraryNotifier, {
    required RecommendationPreferences Function() preferencesResolver,
    required Future<void> Function() ensurePreferencesLoaded,
    required Future<void> Function() startRecommendationSession,
  })  : _preferencesResolver = preferencesResolver,
        _ensurePreferencesLoaded = ensurePreferencesLoaded,
        _startRecommendationSession = startRecommendationSession,
        resolver = PlaybackUrlResolver(
          youtubeService: youtubeService,
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
    if (state.isPlaying) {
      await nativePlayerService.pause();
    } else {
      await nativePlayerService.resume();
    }
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
