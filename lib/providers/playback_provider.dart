import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/youtube_service.dart';
import 'library_provider.dart';
import '../services/native_player_service.dart';

class PlaybackFailure implements Exception {
  const PlaybackFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

final nativePlayerServiceProvider = Provider<NativePlayerService>((ref) {
  return NativePlayerService();
});

final playbackNotifierProvider = StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) {
  final youtubeService = ref.read(youtubeServiceProvider);
  final nativePlayerService = ref.read(nativePlayerServiceProvider);
  final libraryNotifier = ref.read(libraryProvider.notifier);
  return PlaybackNotifier(nativePlayerService, youtubeService, libraryNotifier);
});

class RecentlyPlayedTrack {
  const RecentlyPlayedTrack({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final String thumbnailUrl;
}

enum PlaybackRepeatMode {
  off,
  one,
  all,
}

class PlaybackState {
  final String? currentTrackId;
  final String? currentTitle;
  final String? currentArtist;
  final String? currentThumbnailUrl;
  final String? currentVideoUrl;
  final bool isPreparing;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final PlaybackRepeatMode? _repeatMode;
  final String? lastError;
  final List<RecentlyPlayedTrack>? _recentlyPlayed;

  List<RecentlyPlayedTrack> get recentlyPlayed => _recentlyPlayed ?? const [];
  PlaybackRepeatMode get repeatMode => _repeatMode ?? PlaybackRepeatMode.off;

  PlaybackState({
    this.currentTrackId,
    this.currentTitle,
    this.currentArtist,
    this.currentThumbnailUrl,
    this.currentVideoUrl,
    this.isPreparing = false,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    PlaybackRepeatMode? repeatMode,
    this.lastError,
    List<RecentlyPlayedTrack>? recentlyPlayed,
  })  : _repeatMode = repeatMode,
        _recentlyPlayed = recentlyPlayed;
  
  PlaybackState copyWith({
    String? currentTrackId,
    String? currentTitle,
    String? currentArtist,
    String? currentThumbnailUrl,
    String? currentVideoUrl,
    bool? isPreparing,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    PlaybackRepeatMode? repeatMode,
    List<RecentlyPlayedTrack>? recentlyPlayed,
    Object? lastError = _playbackStateNoChange,
  }) {
    return PlaybackState(
      currentTrackId: currentTrackId ?? this.currentTrackId,
      currentTitle: currentTitle ?? this.currentTitle,
      currentArtist: currentArtist ?? this.currentArtist,
      currentThumbnailUrl: currentThumbnailUrl ?? this.currentThumbnailUrl,
      currentVideoUrl: currentVideoUrl ?? this.currentVideoUrl,
      isPreparing: isPreparing ?? this.isPreparing,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      lastError: identical(lastError, _playbackStateNoChange)
          ? this.lastError
          : lastError as String?,
    );
  }
}

const Object _playbackStateNoChange = Object();

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  static const MethodChannel _extractChannel = MethodChannel('audiodockr/extract');

  final NativePlayerService _nativePlayerService;
  final YoutubeService _youtubeService;
  final LibraryNotifier _libraryNotifier;
  StreamSubscription<Map<String, dynamic>>? _playerEventsSubscription;

  PlaybackNotifier(this._nativePlayerService, this._youtubeService, this._libraryNotifier)
      : super(PlaybackState()) {
    _playerEventsSubscription = _nativePlayerService.playerStateStream.listen(
      _handleNativePlayerEvent,
    );
  }

  Future<void> playTrack(String videoId, String videoUrl, String title, String artist, String thumbnailUrl) async {
    await _ensurePlaybackPermissions();
    try {
      state = state.copyWith(
        currentTrackId: videoId,
        currentTitle: title,
        currentArtist: artist,
        currentThumbnailUrl: thumbnailUrl,
        currentVideoUrl: videoUrl,
        position: Duration.zero,
        duration: Duration.zero,
        isPreparing: true,
        lastError: null,
      );
      final audioUrl = await _extractTrackUrl(videoId, videoUrl);

      if (audioUrl == null || audioUrl.isEmpty) {
        state = state.copyWith(isPreparing: false);
        throw const PlaybackFailure(
          'extract_empty',
          'Audio playback could not be prepared.',
        );
      }

      await _nativePlayerService.playYoutubeStream(
        url: audioUrl,
        headers: _buildPlaybackHeaders(),
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
      );
      unawaited(
        _libraryNotifier.recordTrack(
          videoId: videoId,
          videoUrl: videoUrl,
          title: title,
          artist: artist,
          thumbnailUrl: thumbnailUrl,
        ).catchError((_) {}),
      );
      state = state.copyWith(
        currentTrackId: videoId,
        currentTitle: title,
        currentArtist: artist,
        currentThumbnailUrl: thumbnailUrl,
        currentVideoUrl: videoUrl,
        position: Duration.zero,
        duration: Duration.zero,
        isPreparing: false,
        recentlyPlayed: _updatedRecentlyPlayed(
          videoId: videoId,
          videoUrl: videoUrl,
          title: title,
          artist: artist,
          thumbnailUrl: thumbnailUrl,
        ),
        lastError: null,
      );
    } catch (e) {
      state = state.copyWith(isPreparing: false);
      throw PlaybackFailure(
        'playback_failed',
        e.toString(),
      );
    }
  }

  List<RecentlyPlayedTrack> _updatedRecentlyPlayed({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) {
    final track = RecentlyPlayedTrack(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
    );

    final filtered = state.recentlyPlayed
        .where((item) => item.videoId != videoId)
        .toList();
    return [track, ...filtered].take(8).toList(growable: false);
  }

  void _handleNativePlayerEvent(Map<String, dynamic> event) {
    final error = event['error'] as String?;
    state = state.copyWith(
      isPreparing: false,
      isPlaying: event['isPlaying'] as bool? ?? state.isPlaying,
      position: Duration(milliseconds: (event['position'] as num?)?.toInt() ?? state.position.inMilliseconds),
      duration: Duration(milliseconds: (event['duration'] as num?)?.toInt() ?? state.duration.inMilliseconds),
      repeatMode: _repeatModeFromNative(event['repeatMode'] as String?),
      lastError: error,
    );
  }

  PlaybackRepeatMode _repeatModeFromNative(String? mode) {
    switch (mode) {
      case 'one':
        return PlaybackRepeatMode.one;
      case 'all':
        return PlaybackRepeatMode.all;
      default:
        return PlaybackRepeatMode.off;
    }
  }

  Map<String, String> _buildPlaybackHeaders() {
    return const {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
      'Referer': 'https://music.youtube.com/',
      'Origin': 'https://music.youtube.com',
      'Accept-Language': 'en-US,en;q=0.9',
    };
  }

  Future<void> _ensurePlaybackPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final status = await Permission.notification.status;
    if (status.isDenied) {
      final requested = await Permission.notification.request();
      if (!requested.isGranted) {
        throw const PlaybackFailure(
          'notification_permission_denied',
          'Notification permission is required for background playback on Android.',
        );
      }
    }
  }

  Future<String?> _extractTrackUrl(String videoId, String videoUrl) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final nativeUrl = await _extractChannel.invokeMethod<String>(
          'extract',
          {
            'videoId': videoId,
            'videoUrl': videoUrl,
          },
        );
        return nativeUrl;
      }

      return await _youtubeService.extractAudioUrl(
        videoId: videoId,
        videoUrl: videoUrl,
      );
    } on PlatformException catch (error) {
      throw PlaybackFailure(
        error.code,
        error.message ?? 'Unable to prepare audio playback for this track.',
      );
    } on YoutubeServiceException catch (error) {
      throw _mapExtractError(error);
    }
  }

  PlaybackFailure _mapExtractError(YoutubeServiceException error) {
    switch (error.code) {
      case 'temporary_unavailable':
        return const PlaybackFailure(
          'temporary_unavailable',
          'YouTube is temporarily unavailable. Please try playing this track again.',
        );
      case 'rate_limited':
        return const PlaybackFailure(
          'rate_limited',
          'YouTube is rate limiting playback requests right now. Try again soon.',
        );
      case 'unsupported_response':
        return const PlaybackFailure(
          'unsupported_response',
          'YouTube returned an unsupported playback response.',
        );
      case 'extract_failed':
        return const PlaybackFailure(
          'extract_failed',
          'Unable to prepare audio playback for this track.',
        );
      default:
        return PlaybackFailure(
          error.code,
          error.message,
        );
    }
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _nativePlayerService.pause();
    } else {
      await _nativePlayerService.resume();
    }
  }

  Future<void> seek(Duration pos) async {
    await _nativePlayerService.seekTo(pos.inMilliseconds);
  }

  Future<void> cycleRepeatMode() async {
    final nextMode = switch (state.repeatMode) {
      PlaybackRepeatMode.off => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.off,
    };

    await _nativePlayerService.setRepeatMode(
      switch (nextMode) {
        PlaybackRepeatMode.off => 'off',
        PlaybackRepeatMode.one => 'one',
        PlaybackRepeatMode.all => 'all',
      },
    );

    state = state.copyWith(repeatMode: nextMode);
  }

  @override
  void dispose() {
    _playerEventsSubscription?.cancel();
    super.dispose();
  }
}
