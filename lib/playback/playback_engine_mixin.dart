import 'dart:async';
import 'dart:io';

import 'playback_models.dart';
import 'playback_notifier.dart';
import 'playback_url_resolver.dart';

mixin PlaybackEngineMixin on PlaybackNotifierBase {
  @override
  Future<void> playTrackInternal({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    String? localFilePath,
  }) async {
    await PlaybackUrlResolver.ensurePlaybackPermissions();

    try {
      await nativePlayerService.pause();
    } catch (_) {}

    // Try local file first (offline playback)
    if (localFilePath != null && localFilePath.isNotEmpty) {
      final localFile = File(localFilePath);
      if (await localFile.exists()) {
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

          await nativePlayerService.playLocalFile(
            filePath: localFilePath,
            title: title,
            artist: artist,
            thumbnailUrl: thumbnailUrl,
          );
          lastTrackStart = DateTime.now();

          unawaited(
            libraryNotifier
                .recordTrack(
                  videoId: videoId,
                  videoUrl: videoUrl,
                  title: title,
                  artist: artist,
                  thumbnailUrl: thumbnailUrl,
                )
                .catchError((_) {}),
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
            isPlaying: true,
            recentlyPlayed: updatedRecentlyPlayed(
              videoId: videoId,
              videoUrl: videoUrl,
              title: title,
              artist: artist,
              thumbnailUrl: thumbnailUrl,
            ),
            lastError: null,
          );
          return;
        } catch (_) {
          // Local playback failed, fall through to online
        }
      }
    }

    // Online playback
    final resolvedMedia = await resolver.resolveVideoUrlIfNeeded(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
    );

    try {
      state = state.copyWith(
        currentTrackId: videoId,
        currentTitle: title,
        currentArtist: artist,
        currentThumbnailUrl: thumbnailUrl,
        currentVideoUrl: resolvedMedia.videoUrl,
        position: Duration.zero,
        duration: Duration.zero,
        isPreparing: true,
        lastError: null,
      );

      final audioUrl = await resolver.extractTrackUrl(
        resolvedMedia.realYoutubeId,
        resolvedMedia.videoUrl,
      );

      if (audioUrl == null || audioUrl.isEmpty) {
        state = state.copyWith(isPreparing: false);
        throw const PlaybackFailure(
            'extract_empty', 'Audio playback could not be prepared.');
      }

      await nativePlayerService.playYoutubeStream(
        url: audioUrl,
        headers: PlaybackUrlResolver.buildPlaybackHeaders(),
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
      );
      lastTrackStart = DateTime.now();

      unawaited(
        libraryNotifier
            .recordTrack(
              videoId: videoId,
              videoUrl: resolvedMedia.videoUrl,
              title: title,
              artist: artist,
              thumbnailUrl: thumbnailUrl,
            )
            .catchError((_) {}),
      );

      state = state.copyWith(
        currentTrackId: videoId,
        currentTitle: title,
        currentArtist: artist,
        currentThumbnailUrl: thumbnailUrl,
        currentVideoUrl: resolvedMedia.videoUrl,
        position: Duration.zero,
        duration: Duration.zero,
        isPreparing: false,
        isPlaying: true,
        recentlyPlayed: updatedRecentlyPlayed(
          videoId: videoId,
          videoUrl: resolvedMedia.videoUrl,
          title: title,
          artist: artist,
          thumbnailUrl: thumbnailUrl,
        ),
        lastError: null,
      );
    } catch (e) {
      state = state.copyWith(isPreparing: false);
      throw PlaybackFailure('playback_failed', e.toString());
    }
  }

  @override
  Future<void> playNextQueuedTrack() async {
    if (isAdvancingQueue || state.queue.isEmpty) return;

    isAdvancingQueue = true;
    final current = currentTrackSnapshot();
    if (current != null) history.add(current);

    try {
      await advanceQueue();
    } on PlaybackFailure catch (error) {
      state = state.copyWith(lastError: error.message);
    } finally {
      isAdvancingQueue = false;
    }
  }

  @override
  Future<void> advanceQueue() async {
    PlaybackFailure? lastFailure;

    while (state.queue.isNotEmpty) {
      final queuedTrack = state.queue.first;
      state =
          state.copyWith(queue: state.queue.skip(1).toList(growable: false));

      try {
        final playableTrack =
            await resolver.resolveQueuedTrackIfNeeded(queuedTrack);
        await playTrackInternal(
          videoId: playableTrack.videoId,
          videoUrl: playableTrack.videoUrl,
          title: playableTrack.title,
          artist: playableTrack.artist,
          thumbnailUrl: playableTrack.thumbnailUrl,
        );
        return;
      } on PlaybackFailure catch (error) {
        lastFailure = error;
        state = state.copyWith(lastError: error.message);
        if (error.code == 'rate_limited' ||
            error.code == 'temporary_unavailable') {
          break;
        }
      }
    }

    if (lastFailure != null) throw lastFailure;
  }

  List<RecentlyPlayedTrack> updatedRecentlyPlayed({
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
    return [
      track,
      ...state.recentlyPlayed.where((t) => t.videoId != videoId),
    ].take(8).toList(growable: false);
  }

  @override
  QueuedTrack? currentTrackSnapshot() {
    final id = state.currentTrackId;
    if (id == null) return null;
    return QueuedTrack(
      videoId: id,
      videoUrl: state.currentVideoUrl ?? '',
      title: state.currentTitle ?? 'Unknown track',
      artist: state.currentArtist ?? 'Unknown artist',
      thumbnailUrl: state.currentThumbnailUrl ?? '',
    );
  }
}
