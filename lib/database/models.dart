class StoredTrack {
  const StoredTrack({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.thumbnailUrl,
    required this.reaction,
    required this.lastPlayedAt,
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

  factory StoredTrack.fromMap(Map<String, Object?> map) {
    return StoredTrack(
      videoId: (map['video_id'] as String?) ?? '',
      videoUrl: (map['video_url'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'Unknown title',
      artist: (map['artist'] as String?) ?? 'Unknown artist',
      durationSeconds: (map['duration'] as int?) ?? 0,
      thumbnailUrl: (map['thumbnail_url'] as String?) ?? '',
      reaction: (map['state'] as String?) ?? 'neutral',
      lastPlayedAt: (map['last_played_at'] as int?) ?? 0,
      hiddenInPlaylist: ((map['hidden_in_playlist'] as int?) ?? 0) == 1,
    );
  }
}

class StoredPlaylist {
  const StoredPlaylist({
    required this.id,
    required this.name,
    required this.trackCount,
    required this.coverImagePath,
    this.lastOpenedAt = 0,
    this.isPinned = false,
  });

  final String id;
  final String name;
  final int trackCount;
  final String coverImagePath;
  final int lastOpenedAt;
  final bool isPinned;
}

class TrackWriteData {
  const TrackWriteData({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.thumbnailUrl,
    this.lastPlayedAt = 0,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final int durationSeconds;
  final String thumbnailUrl;
  final int lastPlayedAt;
}
