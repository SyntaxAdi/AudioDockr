import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database_helper.dart';
import '../services/spotify_import_service.dart';
import 'library_models.dart';
import 'library_state.dart';

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._db) : super(const LibraryState()) {
    _loadLibrary();
  }

  final DatabaseHelper _db;

  // ── Mapping helpers ───────────────────────────────────────────────────────

  List<LibraryTrack> _mapTracks(List<StoredTrack> tracks) =>
      tracks.map(LibraryTrack.fromStoredTrack).toList();

  List<LibraryPlaylist> _mapPlaylists(List<StoredPlaylist> playlists) =>
      playlists.map(LibraryPlaylist.fromStoredPlaylist).toList();

  // ── Initial load ──────────────────────────────────────────────────────────

  Future<void> _loadLibrary() async {
    final results = await Future.wait([
      _db.fetchAllTracks(),
      _db.fetchLikedTracks(),
      _db.fetchPlaylists(),
      _db.fetchRecentlyPlayed(),
      _db.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      isLoading: false,
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      likedTracks: _mapTracks(results[1] as List<StoredTrack>),
      playlists: _mapPlaylists(results[2] as List<StoredPlaylist>),
      recentTracks: _mapTracks(results[3] as List<StoredTrack>),
      recentPlaylists: _mapPlaylists(results[4] as List<StoredPlaylist>),
    );
  }

  // ── Track recording ───────────────────────────────────────────────────────

  Future<void> recordTrack({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    await _db.saveTrack(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
    );
    final results = await Future.wait([
      _db.fetchAllTracks(),
      _db.fetchRecentlyPlayed(),
      _db.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      recentTracks: _mapTracks(results[1] as List<StoredTrack>),
      recentPlaylists: _mapPlaylists(results[2] as List<StoredPlaylist>),
    );
  }

  Future<void> recordPlaylistOpened(String playlistId) async {
    await _db.recordPlaylistOpened(playlistId);
    final recentPlaylists = await _db.fetchRecentlyOpenedPlaylists();
    state = state.copyWith(recentPlaylists: _mapPlaylists(recentPlaylists));
  }

  Future<void> updateTrackVideoUrl({
    required String videoId,
    required String videoUrl,
  }) async {
    await _db.updateTrackVideoUrl(videoId: videoId, videoUrl: videoUrl);
    final results = await Future.wait([
      _db.fetchAllTracks(),
      _db.fetchLikedTracks(),
      _db.fetchRecentlyPlayed(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0]),
      likedTracks: _mapTracks(results[1]),
      recentTracks: _mapTracks(results[2]),
    );
  }

  // ── Playlist management ───────────────────────────────────────────────────

  Future<void> createPlaylist(String name) async {
    await _db.createPlaylist(name);
    await _reloadPlaylistsAndRecent();
  }

  Future<void> updatePlaylist({
    required String playlistId,
    required String name,
    required String coverImagePath,
  }) async {
    await _db.updatePlaylist(
      playlistId: playlistId,
      name: name,
      coverImagePath: coverImagePath,
    );
    await _reloadPlaylistsAndRecent();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _db.deletePlaylist(playlistId);
    await _reloadAll();
  }

  Future<void> setTrackHiddenInPlaylist({
    required String playlistId,
    required String videoId,
    required bool hidden,
  }) async {
    await _db.setTrackHiddenInPlaylist(
      playlistId: playlistId,
      videoId: videoId,
      hidden: hidden,
    );
    await _reloadPlaylistsAndRecent();
  }

  // ── Playlist membership ───────────────────────────────────────────────────

  Future<bool> addTrackToPlaylist({
    required String playlistId,
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    final added = await _db.addTrackToPlaylist(
      playlistId: playlistId,
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
    );
    final results = await Future.wait([
      _db.fetchAllTracks(),
      _db.fetchPlaylists(),
      _db.fetchRecentlyPlayed(),
      _db.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      playlists: _mapPlaylists(results[1] as List<StoredPlaylist>),
      recentTracks: _mapTracks(results[2] as List<StoredTrack>),
      recentPlaylists: _mapPlaylists(results[3] as List<StoredPlaylist>),
    );
    return added;
  }

  Future<Set<String>> fetchSavedPlaylistIds(String videoId) async {
    if (videoId.isEmpty) return const {};
    return _db.fetchPlaylistIdsForTrack(videoId);
  }

  Future<List<LibraryTrack>> fetchPlaylistTracks(String playlistId) async {
    final tracks = await _db.fetchPlaylistTracks(playlistId);
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
      await _setReaction(
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
      await _db.addTrackToPlaylist(
        playlistId: playlistId,
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
      );
    } else {
      await _db.removeTrackFromPlaylist(playlistId: playlistId, videoId: videoId);
    }

    await _reloadAll();
    return shouldSave;
  }

  // ── Reactions ─────────────────────────────────────────────────────────────

  Future<void> toggleLike({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    final nextReaction = trackById(videoId)?.isLiked == true ? 'neutral' : 'liked';
    await _setReaction(
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
    await _setReaction(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      reaction: nextReaction,
    );
  }

  Future<void> _setReaction({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
    required String reaction,
  }) async {
    await _db.setTrackReaction(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      reaction: reaction,
    );
    final results = await Future.wait([
      _db.fetchAllTracks(),
      _db.fetchLikedTracks(),
      _db.fetchPlaylists(),
      _db.fetchRecentlyPlayed(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      likedTracks: _mapTracks(results[1] as List<StoredTrack>),
      playlists: _mapPlaylists(results[2] as List<StoredPlaylist>),
      recentTracks: _mapTracks(results[3] as List<StoredTrack>),
    );
  }

  // ── Spotify import ────────────────────────────────────────────────────────

  Future<String> importSpotifyPlaylist(List<SpotifyImportTrack> tracks) async {
    if (tracks.isEmpty) return '';

    final playlistName = 'Spotify Playlist ${_nextSpotifyPlaylistNumber()}';
    final playlistId = await _db.createPlaylist(playlistName);

    final importSeed = DateTime.now().millisecondsSinceEpoch;
    final importedTracks = [
      for (var i = 0; i < tracks.length; i++)
        TrackWriteData(
          videoId: 'spotify_import_${importSeed}_$i',
          videoUrl: '',
          title: tracks[i].songName,
          artist: tracks[i].artistName,
          durationSeconds: 0,
          thumbnailUrl: tracks[i].thumbnailUrl,
          lastPlayedAt: 0,
        ),
    ];

    await _db.addTracksToPlaylistBulk(
      playlistId: playlistId,
      tracks: importedTracks,
    );

    await _reloadAll();
    return playlistName;
  }

  int _nextSpotifyPlaylistNumber() {
    final pattern = RegExp(r'^Spotify Playlist (\d+)$');
    var max = 0;
    for (final playlist in state.userPlaylists) {
      final n = int.tryParse(pattern.firstMatch(playlist.name)?.group(1) ?? '');
      if (n != null && n > max) max = n;
    }
    return max + 1;
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  LibraryTrack? trackById(String? videoId) {
    if (videoId == null) return null;
    for (final track in state.allTracks) {
      if (track.videoId == videoId) return track;
    }
    return null;
  }

  LibraryPlaylist? playlistById(String? playlistId) {
    if (playlistId == null) return null;
    for (final playlist in state.playlists) {
      if (playlist.id == playlistId) return playlist;
    }
    return null;
  }

  // ── Reload helpers ────────────────────────────────────────────────────────

  Future<void> _reloadPlaylistsAndRecent() async {
    final results = await Future.wait([
      _db.fetchPlaylists(),
      _db.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      playlists: _mapPlaylists(results[0]),
      recentPlaylists: _mapPlaylists(results[1]),
    );
  }

  Future<void> _reloadAll() async {
    final results = await Future.wait([
      _db.fetchAllTracks(),
      _db.fetchLikedTracks(),
      _db.fetchPlaylists(),
      _db.fetchRecentlyPlayed(),
      _db.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      likedTracks: _mapTracks(results[1] as List<StoredTrack>),
      playlists: _mapPlaylists(results[2] as List<StoredPlaylist>),
      recentTracks: _mapTracks(results[3] as List<StoredTrack>),
      recentPlaylists: _mapPlaylists(results[4] as List<StoredPlaylist>),
    );
  }
}
