import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database_helper.dart';

class LibraryTrack {
  const LibraryTrack({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.thumbnailUrl,
    required this.reaction,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final int durationSeconds;
  final String thumbnailUrl;
  final String reaction;

  bool get isLiked => reaction == 'liked';
  bool get isDisliked => reaction == 'disliked';

  factory LibraryTrack.fromStoredTrack(StoredTrack track) {
    return LibraryTrack(
      videoId: track.videoId,
      videoUrl: track.videoUrl,
      title: track.title,
      artist: track.artist,
      durationSeconds: track.durationSeconds,
      thumbnailUrl: track.thumbnailUrl,
      reaction: track.reaction,
    );
  }
}

class LibraryPlaylist {
  const LibraryPlaylist({
    required this.id,
    required this.name,
    required this.trackCount,
    this.coverImagePath = '',
  });

  final String id;
  final String name;
  final int trackCount;
  final String coverImagePath;

  factory LibraryPlaylist.fromStoredPlaylist(StoredPlaylist playlist) {
    return LibraryPlaylist(
      id: playlist.id,
      name: playlist.name,
      trackCount: playlist.trackCount,
      coverImagePath: playlist.coverImagePath,
    );
  }
}

class LibraryState {
  const LibraryState({
    this.isLoading = true,
    this.allTracks = const [],
    this.likedTracks = const [],
    this.playlists = const [],
    this.recentTracks = const [],
  });

  final bool isLoading;
  final List<LibraryTrack> allTracks;
  final List<LibraryTrack> likedTracks;
  final List<LibraryPlaylist> playlists;
  final List<LibraryTrack> recentTracks;
  List<LibraryPlaylist> get userPlaylists =>
      playlists.where((playlist) => playlist.id != likedPlaylistId).toList();

  LibraryState copyWith({
    bool? isLoading,
    List<LibraryTrack>? allTracks,
    List<LibraryTrack>? likedTracks,
    List<LibraryPlaylist>? playlists,
    List<LibraryTrack>? recentTracks,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      allTracks: allTracks ?? this.allTracks,
      likedTracks: likedTracks ?? this.likedTracks,
      playlists: playlists ?? this.playlists,
      recentTracks: recentTracks ?? this.recentTracks,
    );
  }
}

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(DatabaseHelper.instance);
});

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._databaseHelper) : super(const LibraryState()) {
    _loadLibrary();
  }

  final DatabaseHelper _databaseHelper;

  Future<void> _loadLibrary() async {
    final allTracks = await _databaseHelper.fetchAllTracks();
    final likedTracks = await _databaseHelper.fetchLikedTracks();
    final playlists = await _databaseHelper.fetchPlaylists();
    final recentTracks = await _databaseHelper.fetchRecentlyPlayed();
    state = state.copyWith(
      isLoading: false,
      allTracks: allTracks.map(LibraryTrack.fromStoredTrack).toList(),
      likedTracks: likedTracks.map(LibraryTrack.fromStoredTrack).toList(),
      playlists: playlists.map(LibraryPlaylist.fromStoredPlaylist).toList(),
      recentTracks: recentTracks.map(LibraryTrack.fromStoredTrack).toList(),
    );
  }

  Future<void> recordTrack({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    await _databaseHelper.saveTrack(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
    );
    await _loadLibrary();
  }

  Future<void> createPlaylist(String name) async {
    await _databaseHelper.createPlaylist(name);
    await _loadLibrary();
  }

  Future<void> updatePlaylist({
    required String playlistId,
    required String name,
    required String coverImagePath,
  }) async {
    await _databaseHelper.updatePlaylist(
      playlistId: playlistId,
      name: name,
      coverImagePath: coverImagePath,
    );
    await _loadLibrary();
  }

  Future<bool> addTrackToPlaylist({
    required String playlistId,
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    final added = await _databaseHelper.addTrackToPlaylist(
      playlistId: playlistId,
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
    );
    await _loadLibrary();
    return added;
  }

  Future<List<LibraryTrack>> fetchPlaylistTracks(String playlistId) async {
    final tracks = await _databaseHelper.fetchPlaylistTracks(playlistId);
    return tracks.map(LibraryTrack.fromStoredTrack).toList();
  }

  Future<void> toggleLike({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    final existing = trackById(videoId);
    final nextReaction = existing?.isLiked == true ? 'neutral' : 'liked';
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
    final existing = trackById(videoId);
    final nextReaction =
        existing?.isDisliked == true ? 'neutral' : 'disliked';
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
    await _databaseHelper.setTrackReaction(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      reaction: reaction,
    );
    await _loadLibrary();
  }

  LibraryTrack? trackById(String? videoId) {
    if (videoId == null) {
      return null;
    }

    for (final track in state.allTracks) {
      if (track.videoId == videoId) {
        return track;
      }
    }
    return null;
  }

  LibraryPlaylist? playlistById(String? playlistId) {
    if (playlistId == null) {
      return null;
    }

    for (final playlist in state.playlists) {
      if (playlist.id == playlistId) {
        return playlist;
      }
    }
    return null;
  }
}
