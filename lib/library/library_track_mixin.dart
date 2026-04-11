import '../database_helper.dart';
import 'library_notifier.dart';

mixin LibraryTrackMixin on LibraryNotifierBase {
  Future<void> recordTrack({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    await db.saveTrack(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
    );
    final results = await Future.wait([
      db.fetchAllTracks(),
      db.fetchRecentlyPlayed(),
      db.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      allTracks: mapTracks(results[0] as List<StoredTrack>),
      recentTracks: mapTracks(results[1] as List<StoredTrack>),
      recentPlaylists: mapPlaylists(results[2] as List<StoredPlaylist>),
    );
  }

  Future<void> recordPlaylistOpened(String playlistId) async {
    await db.recordPlaylistOpened(playlistId);
    final recentPlaylists = await db.fetchRecentlyOpenedPlaylists();
    state = state.copyWith(recentPlaylists: mapPlaylists(recentPlaylists));
  }

  Future<void> updateTrackVideoUrl({
    required String videoId,
    required String videoUrl,
  }) async {
    await db.updateTrackVideoUrl(videoId: videoId, videoUrl: videoUrl);
    final results = await Future.wait([
      db.fetchAllTracks(),
      db.fetchLikedTracks(),
      db.fetchRecentlyPlayed(),
    ]);
    state = state.copyWith(
      allTracks: mapTracks(results[0]),
      likedTracks: mapTracks(results[1]),
      recentTracks: mapTracks(results[2]),
    );
  }
}
