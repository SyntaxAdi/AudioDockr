import 'dart:async';

import 'playback_models.dart';
import 'playback_notifier.dart';


enum NativePlaybackState { idle, buffering, ready, ended }

mixin PlaybackEventMixin on PlaybackNotifierBase {
  @override
  void handleNativePlayerEvent(Map<String, dynamic> event) {
    // Handle skip events from the notification media controls.
    final eventType = event['type'] as String?;
    final eventName = event['name'] as String?;
    if (eventType == 'event') {
      if (eventName == 'skip_next') {
        unawaited(nextTrack());
      } else if (eventName == 'skip_previous') {
        unawaited(previousTrack());
      }
      return;
    }

    if (state.isPreparing) return;

    final isPlaying = event['isPlaying'] as bool? ?? state.isPlaying;
    final nativeState =
        nativePlaybackStateFromEvent(event['playbackState'] as String?);
    final position = Duration(
      milliseconds:
          (event['position'] as num?)?.toInt() ?? state.position.inMilliseconds,
    );
    final duration = Duration(
      milliseconds:
          (event['duration'] as num?)?.toInt() ?? state.duration.inMilliseconds,
    );

    if (lastTrackStart != null &&
        DateTime.now().difference(lastTrackStart!) <
            const Duration(milliseconds: 1500) &&
        position > const Duration(seconds: 3)) {
      return;
    }

    state = state.copyWith(
      isPreparing: false,
      isPlaying: isPlaying,
      position: position,
      duration: duration,
      repeatMode: repeatModeFromNative(event['repeatMode'] as String?),
      lastError: event['error'] as String?,
    );

    if (!isPlaying &&
        !isAdvancingQueue &&
        nativeState == NativePlaybackState.ended &&
        state.repeatMode == PlaybackRepeatMode.off &&
        state.queue.isNotEmpty &&
        duration > Duration.zero &&
        position >= duration) {
      unawaited(playNextQueuedTrack());
    }
  }

  PlaybackRepeatMode repeatModeFromNative(String? mode) => switch (mode) {
        'one' => PlaybackRepeatMode.one,
        'all' => PlaybackRepeatMode.all,
        _ => PlaybackRepeatMode.off,
      };

  NativePlaybackState nativePlaybackStateFromEvent(String? s) => switch (s) {
        'buffering' => NativePlaybackState.buffering,
        'ready' => NativePlaybackState.ready,
        'ended' => NativePlaybackState.ended,
        _ => NativePlaybackState.idle,
      };
}
