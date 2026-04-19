class PlaybackFailure implements Exception {
  const PlaybackFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class RecentlyPlayedTrack {
  const RecentlyPlayedTrack({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final String thumbnailUrl;
}

class QueuedTrack {
  const QueuedTrack({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.localFilePath,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String? localFilePath;

  QueuedTrack copyWith({
    String? videoId,
    String? videoUrl,
    String? title,
    String? artist,
    String? thumbnailUrl,
    Object? localFilePath = _playbackUnsetField,
  }) {
    return QueuedTrack(
      videoId: videoId ?? this.videoId,
      videoUrl: videoUrl ?? this.videoUrl,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localFilePath: identical(localFilePath, _playbackUnsetField)
          ? this.localFilePath
          : localFilePath as String?,
    );
  }
}

const Object _playbackUnsetField = Object();

enum PlaybackRepeatMode {
  off,
  one,
  all,
}
