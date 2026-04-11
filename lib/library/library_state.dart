import 'library_models.dart';

const String likedPlaylistId = 'liked';

class LibraryState {
  const LibraryState({
    this.isLoading = true,
    this.allTracks = const [],
    this.likedTracks = const [],
    this.playlists = const [],
    this.recentTracks = const [],
    List<LibraryPlaylist>? recentPlaylists,
  }) : _recentPlaylists = recentPlaylists;

  final bool isLoading;
  final List<LibraryTrack> allTracks;
  final List<LibraryTrack> likedTracks;
  final List<LibraryPlaylist> playlists;
  final List<LibraryTrack> recentTracks;
  final List<LibraryPlaylist>? _recentPlaylists;

  List<LibraryPlaylist> get recentPlaylists => _recentPlaylists ?? const [];
  List<LibraryPlaylist> get userPlaylists =>
      playlists.where((p) => p.id != likedPlaylistId).toList();

  LibraryState copyWith({
    bool? isLoading,
    List<LibraryTrack>? allTracks,
    List<LibraryTrack>? likedTracks,
    List<LibraryPlaylist>? playlists,
    List<LibraryTrack>? recentTracks,
    List<LibraryPlaylist>? recentPlaylists,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      allTracks: allTracks ?? this.allTracks,
      likedTracks: likedTracks ?? this.likedTracks,
      playlists: playlists ?? this.playlists,
      recentTracks: recentTracks ?? this.recentTracks,
      recentPlaylists: recentPlaylists ?? this.recentPlaylists,
    );
  }
}
