import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database_helper.dart';
import '../services/spotify_import_service.dart';

class LibraryTrack {
  const LibraryTrack({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.thumbnailUrl,
    required this.reaction,
    this.lastPlayedAt = 0,
    bool? hiddenInPlaylist,
  }) : _hiddenInPlaylist = hiddenInPlaylist;

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final int durationSeconds;
  final String thumbnailUrl;
  final String reaction;
  final int lastPlayedAt;
  final bool? _hiddenInPlaylist;
  bool get hiddenInPlaylist => _hiddenInPlaylist ?? false;

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
      lastPlayedAt: track.lastPlayedAt,
      hiddenInPlaylist: track.hiddenInPlaylist,
    );
  }
}

class LibraryPlaylist {
  const LibraryPlaylist({
    required this.id,
    required this.name,
    required this.trackCount,
    this.coverImagePath = '',
    this.lastOpenedAt = 0,
  });

  final String id;
  final String name;
  final int trackCount;
  final String coverImagePath;
  final int lastOpenedAt;

  factory LibraryPlaylist.fromStoredPlaylist(StoredPlaylist playlist) {
    return LibraryPlaylist(
      id: playlist.id,
      name: playlist.name,
      trackCount: playlist.trackCount,
      coverImagePath: playlist.coverImagePath,
      lastOpenedAt: playlist.lastOpenedAt,
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
      playlists.where((playlist) => playlist.id != likedPlaylistId).toList();

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

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(DatabaseHelper.instance);
});

class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._databaseHelper) : super(const LibraryState()) {
    _loadLibrary();
  }

  final DatabaseHelper _databaseHelper;

  List<LibraryTrack> _mapTracks(List<StoredTrack> tracks) {
    return tracks.map(LibraryTrack.fromStoredTrack).toList();
  }

  List<LibraryPlaylist> _mapPlaylists(List<StoredPlaylist> playlists) {
    return playlists.map(LibraryPlaylist.fromStoredPlaylist).toList();
  }

  Future<void> _loadLibrary() async {
    final results = await Future.wait([
      _databaseHelper.fetchAllTracks(),
      _databaseHelper.fetchLikedTracks(),
      _databaseHelper.fetchPlaylists(),
      _databaseHelper.fetchRecentlyPlayed(),
      _databaseHelper.fetchRecentlyOpenedPlaylists(),
    ]);
    final allTracks = results[0] as List<StoredTrack>;
    final likedTracks = results[1] as List<StoredTrack>;
    final playlists = results[2] as List<StoredPlaylist>;
    final recentTracks = results[3] as List<StoredTrack>;
    final recentPlaylists = results[4] as List<StoredPlaylist>;
    state = state.copyWith(
      isLoading: false,
      allTracks: _mapTracks(allTracks),
      likedTracks: _mapTracks(likedTracks),
      playlists: _mapPlaylists(playlists),
      recentTracks: _mapTracks(recentTracks),
      recentPlaylists: _mapPlaylists(recentPlaylists),
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
    final results = await Future.wait([
      _databaseHelper.fetchAllTracks(),
      _databaseHelper.fetchRecentlyPlayed(),
      _databaseHelper.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      recentTracks: _mapTracks(results[1] as List<StoredTrack>),
      recentPlaylists: _mapPlaylists(results[2] as List<StoredPlaylist>),
    );
  }

  Future<void> recordPlaylistOpened(String playlistId) async {
    await _databaseHelper.recordPlaylistOpened(playlistId);
    final recentPlaylists = await _databaseHelper.fetchRecentlyOpenedPlaylists();
    state = state.copyWith(
      recentPlaylists: _mapPlaylists(recentPlaylists),
    );
  }

  Future<void> createPlaylist(String name) async {
    await _databaseHelper.createPlaylist(name);
    final results = await Future.wait([
      _databaseHelper.fetchPlaylists(),
      _databaseHelper.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      playlists: _mapPlaylists(results[0] as List<StoredPlaylist>),
      recentPlaylists: _mapPlaylists(results[1] as List<StoredPlaylist>),
    );
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
    final results = await Future.wait([
      _databaseHelper.fetchPlaylists(),
      _databaseHelper.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      playlists: _mapPlaylists(results[0] as List<StoredPlaylist>),
      recentPlaylists: _mapPlaylists(results[1] as List<StoredPlaylist>),
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _databaseHelper.deletePlaylist(playlistId);
    final results = await Future.wait([
      _databaseHelper.fetchAllTracks(),
      _databaseHelper.fetchLikedTracks(),
      _databaseHelper.fetchPlaylists(),
      _databaseHelper.fetchRecentlyPlayed(),
      _databaseHelper.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      likedTracks: _mapTracks(results[1] as List<StoredTrack>),
      playlists: _mapPlaylists(results[2] as List<StoredPlaylist>),
      recentTracks: _mapTracks(results[3] as List<StoredTrack>),
      recentPlaylists: _mapPlaylists(results[4] as List<StoredPlaylist>),
    );
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
    final results = await Future.wait([
      _databaseHelper.fetchAllTracks(),
      _databaseHelper.fetchPlaylists(),
      _databaseHelper.fetchRecentlyPlayed(),
      _databaseHelper.fetchRecentlyOpenedPlaylists(),
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
    if (videoId.isEmpty) {
      return <String>{};
    }
    return _databaseHelper.fetchPlaylistIdsForTrack(videoId);
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
      await _databaseHelper.addTrackToPlaylist(
        playlistId: playlistId,
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
      );
    } else {
      await _databaseHelper.removeTrackFromPlaylist(
        playlistId: playlistId,
        videoId: videoId,
      );
    }

    final results = await Future.wait([
      _databaseHelper.fetchAllTracks(),
      _databaseHelper.fetchLikedTracks(),
      _databaseHelper.fetchPlaylists(),
      _databaseHelper.fetchRecentlyPlayed(),
      _databaseHelper.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      likedTracks: _mapTracks(results[1] as List<StoredTrack>),
      playlists: _mapPlaylists(results[2] as List<StoredPlaylist>),
      recentTracks: _mapTracks(results[3] as List<StoredTrack>),
      recentPlaylists: _mapPlaylists(results[4] as List<StoredPlaylist>),
    );
    return shouldSave;
  }

  Future<List<LibraryTrack>> fetchPlaylistTracks(String playlistId) async {
    final tracks = await _databaseHelper.fetchPlaylistTracks(playlistId);
    return tracks.map(LibraryTrack.fromStoredTrack).toList();
  }

  Future<void> setTrackHiddenInPlaylist({
    required String playlistId,
    required String videoId,
    required bool hidden,
  }) async {
    await _databaseHelper.setTrackHiddenInPlaylist(
      playlistId: playlistId,
      videoId: videoId,
      hidden: hidden,
    );
    final results = await Future.wait([
      _databaseHelper.fetchPlaylists(),
      _databaseHelper.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      playlists: _mapPlaylists(results[0] as List<StoredPlaylist>),
      recentPlaylists: _mapPlaylists(results[1] as List<StoredPlaylist>),
    );
  }

  Future<String> importSpotifyPlaylist(
    List<SpotifyImportTrack> tracks,
  ) async {
    if (tracks.isEmpty) {
      return '';
    }

    final playlistNumber = _nextSpotifyPlaylistNumber();
    final playlistName = 'Spotify Playlist $playlistNumber';
    final playlistId = await _databaseHelper.createPlaylist(playlistName);

    final importedTracks = <TrackWriteData>[];
    final importSeed = DateTime.now().millisecondsSinceEpoch;
    for (var index = 0; index < tracks.length; index++) {
      final track = tracks[index];
      importedTracks.add(
        TrackWriteData(
          videoId: 'spotify_import_${importSeed}_$index',
          videoUrl: '',
          title: track.songName,
          artist: track.artistName,
          durationSeconds: 0,
          thumbnailUrl: track.thumbnailUrl,
          lastPlayedAt: 0,
        ),
      );
    }

    await _databaseHelper.addTracksToPlaylistBulk(
      playlistId: playlistId,
      tracks: importedTracks,
    );

    final results = await Future.wait([
      _databaseHelper.fetchAllTracks(),
      _databaseHelper.fetchLikedTracks(),
      _databaseHelper.fetchPlaylists(),
      _databaseHelper.fetchRecentlyPlayed(),
      _databaseHelper.fetchRecentlyOpenedPlaylists(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      likedTracks: _mapTracks(results[1] as List<StoredTrack>),
      playlists: _mapPlaylists(results[2] as List<StoredPlaylist>),
      recentTracks: _mapTracks(results[3] as List<StoredTrack>),
      recentPlaylists: _mapPlaylists(results[4] as List<StoredPlaylist>),
    );
    return playlistName;
  }

  Future<void> updateTrackVideoUrl({
    required String videoId,
    required String videoUrl,
  }) async {
    await _databaseHelper.updateTrackVideoUrl(
      videoId: videoId,
      videoUrl: videoUrl,
    );
    final results = await Future.wait([
      _databaseHelper.fetchAllTracks(),
      _databaseHelper.fetchLikedTracks(),
      _databaseHelper.fetchRecentlyPlayed(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      likedTracks: _mapTracks(results[1] as List<StoredTrack>),
      recentTracks: _mapTracks(results[2] as List<StoredTrack>),
    );
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
    final results = await Future.wait([
      _databaseHelper.fetchAllTracks(),
      _databaseHelper.fetchLikedTracks(),
      _databaseHelper.fetchPlaylists(),
      _databaseHelper.fetchRecentlyPlayed(),
    ]);
    state = state.copyWith(
      allTracks: _mapTracks(results[0] as List<StoredTrack>),
      likedTracks: _mapTracks(results[1] as List<StoredTrack>),
      playlists: _mapPlaylists(results[2] as List<StoredPlaylist>),
      recentTracks: _mapTracks(results[3] as List<StoredTrack>),
    );
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

  int _nextSpotifyPlaylistNumber() {
    final pattern = RegExp(r'^Spotify Playlist (\d+)$');
    var maxNumber = 0;
    for (final playlist in state.userPlaylists) {
      final match = pattern.firstMatch(playlist.name);
      final number = int.tryParse(match?.group(1) ?? '');
      if (number != null && number > maxNumber) {
        maxNumber = number;
      }
    }
    return maxNumber + 1;
  }
}
