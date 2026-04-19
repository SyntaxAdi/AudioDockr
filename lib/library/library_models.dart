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
    this.localFilePath,
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
  final String? localFilePath;
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
      localFilePath: null,
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
    this.isPinned = false,
  });

  final String id;
  final String name;
  final int trackCount;
  final String coverImagePath;
  final int lastOpenedAt;
  final bool isPinned;

  factory LibraryPlaylist.fromStoredPlaylist(StoredPlaylist playlist) {
    return LibraryPlaylist(
      id: playlist.id,
      name: playlist.name,
      trackCount: playlist.trackCount,
      coverImagePath: playlist.coverImagePath,
      lastOpenedAt: playlist.lastOpenedAt,
      isPinned: playlist.isPinned,
    );
  }
}
