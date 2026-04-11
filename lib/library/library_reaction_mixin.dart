import '../database_helper.dart';
import 'library_notifier.dart';

mixin LibraryReactionMixin on LibraryNotifierBase {
  Future<void> toggleLike({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    final nextReaction =
        trackById(videoId)?.isLiked == true ? 'neutral' : 'liked';
    await setReaction(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      reaction: nextReaction,
    );
  }

  Future<void> toggleDislike({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    final nextReaction =
        trackById(videoId)?.isDisliked == true ? 'neutral' : 'disliked';
    await setReaction(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      reaction: nextReaction,
    );
  }

  @override
  Future<void> setReaction({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
    required String reaction,
  }) async {
    await db.setTrackReaction(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      reaction: reaction,
    );
    final results = await Future.wait([
      db.fetchAllTracks(),
      db.fetchLikedTracks(),
      db.fetchPlaylists(),
      db.fetchRecentlyPlayed(),
    ]);
    state = state.copyWith(
      allTracks: mapTracks(results[0] as List<StoredTrack>),
      likedTracks: mapTracks(results[1] as List<StoredTrack>),
      playlists: mapPlaylists(results[2] as List<StoredPlaylist>),
      recentTracks: mapTracks(results[3] as List<StoredTrack>),
    );
  }
}
