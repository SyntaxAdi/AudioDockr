import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/youtube_service.dart';
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
  return PlaybackNotifier(nativePlayerService, youtubeService);
});

class PlaybackState {
  final String? currentTrackId;
  final String? currentTitle;
  final String? currentArtist;
  final String? currentThumbnailUrl;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String? lastError;

  PlaybackState({
    this.currentTrackId,
    this.currentTitle,
    this.currentArtist,
    this.currentThumbnailUrl,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.lastError,
  });
  
  PlaybackState copyWith({
    String? currentTrackId,
    String? currentTitle,
    String? currentArtist,
    String? currentThumbnailUrl,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    Object? lastError = _playbackStateNoChange,
  }) {
    return PlaybackState(
      currentTrackId: currentTrackId ?? this.currentTrackId,
      currentTitle: currentTitle ?? this.currentTitle,
      currentArtist: currentArtist ?? this.currentArtist,
      currentThumbnailUrl: currentThumbnailUrl ?? this.currentThumbnailUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
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
  StreamSubscription<Map<String, dynamic>>? _playerEventsSubscription;

  PlaybackNotifier(this._nativePlayerService, this._youtubeService)
      : super(PlaybackState()) {
    _playerEventsSubscription = _nativePlayerService.playerStateStream.listen(
      _handleNativePlayerEvent,
    );
  }

  Future<void> playTrack(String videoId, String videoUrl, String title, String artist, String thumbnailUrl) async {
    await _ensurePlaybackPermissions();
    final audioUrl = await _extractTrackUrl(videoId, videoUrl);

    if (audioUrl == null || audioUrl.isEmpty) {
      throw const PlaybackFailure(
        'extract_empty',
        'Audio playback could not be prepared.',
      );
    }

    try {
      await _nativePlayerService.playYoutubeStream(
        url: audioUrl,
        headers: _buildPlaybackHeaders(),
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
      );
      state = state.copyWith(
        currentTrackId: videoId,
        currentTitle: title,
        currentArtist: artist,
        currentThumbnailUrl: thumbnailUrl,
        position: Duration.zero,
        duration: Duration.zero,
        lastError: null,
      );
    } catch (e) {
      throw PlaybackFailure(
        'playback_failed',
        e.toString(),
      );
    }
  }

  void _handleNativePlayerEvent(Map<String, dynamic> event) {
    final error = event['error'] as String?;
    state = state.copyWith(
      isPlaying: event['isPlaying'] as bool? ?? state.isPlaying,
      position: Duration(milliseconds: (event['position'] as num?)?.toInt() ?? state.position.inMilliseconds),
      duration: Duration(milliseconds: (event['duration'] as num?)?.toInt() ?? state.duration.inMilliseconds),
      lastError: error,
    );
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

  @override
  void dispose() {
    _playerEventsSubscription?.cancel();
    super.dispose();
  }
}
