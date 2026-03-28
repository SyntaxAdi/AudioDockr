import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../api/youtube_service.dart';

class PlaybackFailure implements Exception {
  const PlaybackFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  return AudioPlayer();
});

final playbackNotifierProvider = StateNotifierProvider<PlaybackNotifier, PlaybackState>((ref) {
  final player = ref.read(audioPlayerProvider);
  final youtubeService = ref.read(youtubeServiceProvider);
  return PlaybackNotifier(player, youtubeService);
});

class PlaybackState {
  final String? currentTrackId;
  final String? currentTitle;
  final String? currentArtist;
  final String? currentThumbnailUrl;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  PlaybackState({
    this.currentTrackId,
    this.currentTitle,
    this.currentArtist,
    this.currentThumbnailUrl,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });
  
  PlaybackState copyWith({
    String? currentTrackId,
    String? currentTitle,
    String? currentArtist,
    String? currentThumbnailUrl,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return PlaybackState(
      currentTrackId: currentTrackId ?? this.currentTrackId,
      currentTitle: currentTitle ?? this.currentTitle,
      currentArtist: currentArtist ?? this.currentArtist,
      currentThumbnailUrl: currentThumbnailUrl ?? this.currentThumbnailUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class PlaybackNotifier extends StateNotifier<PlaybackState> {
  static const MethodChannel _extractChannel = MethodChannel('audiodockr/extract');

  final AudioPlayer _player;
  final YoutubeService _youtubeService;

  PlaybackNotifier(this._player, this._youtubeService) : super(PlaybackState()) {
    _player.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });
  }

  Future<void> playTrack(String videoId, String videoUrl, String title, String artist, String thumbnailUrl) async {
    final audioUrl = await _extractTrackUrl(videoId, videoUrl);

    if (audioUrl == null || audioUrl.isEmpty) {
      throw const PlaybackFailure(
        'extract_empty',
        'Audio playback could not be prepared.',
      );
    }

    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(audioUrl),
          tag: MediaItem(
            id: videoId,
            title: title,
            artist: artist,
            artUri: thumbnailUrl.isNotEmpty ? Uri.parse(thumbnailUrl) : null,
          ),
        ),
      );
      _player.play();
      state = state.copyWith(
        currentTrackId: videoId,
        currentTitle: title,
        currentArtist: artist,
        currentThumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      throw PlaybackFailure(
        'playback_failed',
        e.toString(),
      );
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

  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void seek(Duration pos) {
    _player.seek(pos);
  }
}
