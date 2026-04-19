class PlaylistImportException implements Exception {
  const PlaylistImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlaylistImportTrack {
  const PlaylistImportTrack({
    required this.thumbnailUrl,
    required this.songName,
    required this.artistName,
    this.videoUrl = '',
  });

  final String thumbnailUrl;
  final String songName;
  final String artistName;
  final String videoUrl;
}
