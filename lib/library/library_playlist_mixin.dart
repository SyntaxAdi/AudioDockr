import '../database_helper.dart';
import 'library_models.dart';
import 'library_notifier.dart';
import 'library_state.dart';

mixin LibraryPlaylistMixin on LibraryNotifierBase {
  // ── Playlist CRUD ─────────────────────────────────────────────────────────

  Future<void> createPlaylist(String name) async {
    await db.createPlaylist(name);
    await reloadPlaylistsAndRecent();
  }

  Future<void> updatePlaylist({
    required String playlistId,
    required String name,
    required String coverImagePath,
  }) async {
    await db.updatePlaylist(
      playlistId: playlistId,
      name: name,
      coverImagePath: coverImagePath,
    );
    await reloadPlaylistsAndRecent();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await db.deletePlaylist(playlistId);
    await reloadAll();
  }

  Future<void> setTrackHiddenInPlaylist({
    required String playlistId,
    required String videoId,
    required bool hidden,
  }) async {
    await db.setTrackHiddenInPlaylist(
      playlistId: playlistId,
      videoId: videoId,
      hidden: hidden,
    );
    await reloadPlaylistsAndRecent();
  }

  // ── Membership ────────────────────────────────────────────────────────────

  Future<bool> addTrackToPlaylist({
    required String playlistId,
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    final added = await db.addTrackToPlaylist(
      playlistId: playlistId,
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
    );
    final results = await Future.wait([
      db.fetchAllTracks(),
      db.fetchPlaylists(),
      db.fetchRecentlyPlayed(),
      db.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      allTracks: mapTracks(results[0] as List<StoredTrack>),
      playlists: mapPlaylists(results[1] as List<StoredPlaylist>),
      recentTracks: mapTracks(results[2] as List<StoredTrack>),
      recentPlaylists: mapPlaylists(results[3] as List<StoredPlaylist>),
    );
    return added;
  }

  Future<Set<String>> fetchSavedPlaylistIds(String videoId) async {
    if (videoId.isEmpty) return const {};
    return db.fetchPlaylistIdsForTrack(videoId);
  }

  Future<List<LibraryTrack>> fetchPlaylistTracks(String playlistId) async {
    final tracks = await db.fetchPlaylistTracks(playlistId);
    return tracks.map(LibraryTrack.fromStoredTrack).toList();
  }

  Future<bool> setPlaylistMembership({
    required String playlistId,
    required bool shouldSave,
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    if (playlistId == likedPlaylistId) {
      await setReaction(
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
        reaction: shouldSave ? 'liked' : 'neutral',
      );
      return shouldSave;
    }

    if (shouldSave) {
      await db.addTrackToPlaylist(
        playlistId: playlistId,
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
      );
    } else {
      await db.removeTrackFromPlaylist(
          playlistId: playlistId, videoId: videoId);
    }

    await reloadAll();
    return shouldSave;
  }
}
