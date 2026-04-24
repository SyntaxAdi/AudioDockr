import 'dart:math';

import 'playback_models.dart';
import 'playback_notifier.dart';

mixin PlaybackQueueMixin on PlaybackNotifierBase {
  @override
  bool addToQueue({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    String? localFilePath,
  }) {
    if (state.queue.any((t) => t.videoId == videoId)) return false;

    state = state.copyWith(queue: [
      ...state.queue,
      QueuedTrack(
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        localFilePath: localFilePath,
      ),
    ]);
    return true;
  }

  @override
  void updateQueuedTrackThumbnail(String videoId, String thumbnailUrl) {
    var changed = false;
    final updated = state.queue.map((t) {
      if (t.videoId == videoId && t.thumbnailUrl != thumbnailUrl) {
        changed = true;
        return t.copyWith(thumbnailUrl: thumbnailUrl);
      }
      return t;
    }).toList(growable: false);

    // Also update the currently-playing thumbnail if it matches.
    final currentMatch = state.currentTrackId == videoId &&
        (state.currentThumbnailUrl ?? '') != thumbnailUrl;

    if (!changed && !currentMatch) return;

    state = state.copyWith(
      queue: changed ? updated : null,
      currentThumbnailUrl: currentMatch ? thumbnailUrl : null,
    );
  }

  @override
  void setShuffleEnabled(bool enabled) {
    if (state.shuffleEnabled == enabled) return;
    state = state.copyWith(shuffleEnabled: enabled);
  }

  @override
  Future<void> nextTrack() async {
    if (state.queue.isEmpty) {
      await nativePlayerService.pause();
      state = state.copyWith(isPlaying: false);
      return;
    }
    final current = currentTrackSnapshot();
    if (current != null) history.add(current);
    await advanceQueue();
  }

  @override
  Future<void> previousTrack() async {
    if (history.isEmpty) {
      await seek(Duration.zero);
      return;
    }

    final current = currentTrackSnapshot();
    final previous = history.removeLast();
    state = state.copyWith(queue: [
      if (current != null) current,
      ...state.queue,
    ]);

    await playTrackInternal(
      videoId: previous.videoId,
      videoUrl: previous.videoUrl,
      title: previous.title,
      artist: previous.artist,
      thumbnailUrl: previous.thumbnailUrl,
      localFilePath: previous.localFilePath,
    );
  }

  @override
  Future<void> toggleShuffleQueue() async {
    final nextValue = !state.shuffleEnabled;
    var updatedQueue = List<QueuedTrack>.from(state.queue);

    if (nextValue && state.currentTrackId != null && state.isPlaying) {
      updatedQueue = libraryNotifier.state.likedTracks
          .where((t) => t.videoId != state.currentTrackId)
          .map((t) => QueuedTrack(
                videoId: t.videoId,
                videoUrl: t.videoUrl,
                title: t.title,
                artist: t.artist,
                thumbnailUrl: t.thumbnailUrl,
                localFilePath: t.localFilePath,
              ))
          .toList(growable: false);
    }

    if (nextValue && updatedQueue.length > 1) {
      updatedQueue = List<QueuedTrack>.from(updatedQueue)..shuffle(Random());
    }

    state = state.copyWith(shuffleEnabled: nextValue, queue: updatedQueue);
  }

  @override
  void clearQueue() {
    if (state.queue.isEmpty) return;
    state = state.copyWith(queue: const []);
  }
}
