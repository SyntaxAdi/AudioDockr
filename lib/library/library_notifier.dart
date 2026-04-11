import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database_helper.dart';
import 'library_models.dart';
import 'library_playlist_mixin.dart';
import 'library_reaction_mixin.dart';
import 'library_spotify_mixin.dart';
import 'library_state.dart';
import 'library_track_mixin.dart';

abstract class LibraryNotifierBase extends StateNotifier<LibraryState> {
  LibraryNotifierBase() : super(const LibraryState());

  DatabaseHelper get db;

  List<LibraryTrack> mapTracks(List<StoredTrack> tracks);
  List<LibraryPlaylist> mapPlaylists(List<StoredPlaylist> playlists);
  
  Future<void> reloadPlaylistsAndRecent();
  Future<void> reloadAll();
  
  LibraryTrack? trackById(String? videoId);
  LibraryPlaylist? playlistById(String? playlistId);

  Future<void> setReaction({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
    required String reaction,
  });
}

class LibraryNotifier extends LibraryNotifierBase
    with
        LibraryTrackMixin,
        LibraryPlaylistMixin,
        LibraryReactionMixin,
        LibrarySpotifyMixin {
  // ── Dependency (accessible to mixins) ─────────────────────────────────────

  @override
  final DatabaseHelper db;

  // ── Constructor ───────────────────────────────────────────────────────────

  LibraryNotifier(this.db) : super() {
    _loadLibrary();
  }

  // ── Initial load ──────────────────────────────────────────────────────────

  Future<void> _loadLibrary() async {
    final results = await Future.wait([
      db.fetchAllTracks(),
      db.fetchLikedTracks(),
      db.fetchPlaylists(),
      db.fetchRecentlyPlayed(),
      db.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      isLoading: false,
      allTracks: mapTracks(results[0] as List<StoredTrack>),
      likedTracks: mapTracks(results[1] as List<StoredTrack>),
      playlists: mapPlaylists(results[2] as List<StoredPlaylist>),
      recentTracks: mapTracks(results[3] as List<StoredTrack>),
      recentPlaylists: mapPlaylists(results[4] as List<StoredPlaylist>),
    );
  }

  // ── Mapping helpers (shared across mixins) ────────────────────────────────

  @override
  List<LibraryTrack> mapTracks(List<StoredTrack> tracks) =>
      tracks.map(LibraryTrack.fromStoredTrack).toList();

  @override
  List<LibraryPlaylist> mapPlaylists(List<StoredPlaylist> playlists) =>
      playlists.map(LibraryPlaylist.fromStoredPlaylist).toList();

  // ── Reload helpers (shared across mixins) ─────────────────────────────────

  @override
  Future<void> reloadPlaylistsAndRecent() async {
    final results = await Future.wait([
      db.fetchPlaylists(),
      db.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      playlists: mapPlaylists(results[0]),
      recentPlaylists: mapPlaylists(results[1]),
    );
  }

  @override
  Future<void> reloadAll() async {
    final results = await Future.wait([
      db.fetchAllTracks(),
      db.fetchLikedTracks(),
      db.fetchPlaylists(),
      db.fetchRecentlyPlayed(),
      db.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      allTracks: mapTracks(results[0] as List<StoredTrack>),
      likedTracks: mapTracks(results[1] as List<StoredTrack>),
      playlists: mapPlaylists(results[2] as List<StoredPlaylist>),
      recentTracks: mapTracks(results[3] as List<StoredTrack>),
      recentPlaylists: mapPlaylists(results[4] as List<StoredPlaylist>),
    );
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  @override
  LibraryTrack? trackById(String? videoId) {
    if (videoId == null) return null;
    for (final track in state.allTracks) {
      if (track.videoId == videoId) return track;
    }
    return null;
  }

  @override
  LibraryPlaylist? playlistById(String? playlistId) {
    if (playlistId == null) return null;
    for (final playlist in state.playlists) {
      if (playlist.id == playlistId) return playlist;
    }
    return null;
  }
}
