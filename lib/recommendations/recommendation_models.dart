class RecommendedTrack {
  const RecommendedTrack({
    required this.title,
    required this.artist,
    required this.imageUrl,
    this.match,
    this.mbid,
  });

  final String title;
  final String artist;
  final String imageUrl;
  final double? match;
  final String? mbid;

  String get dedupKey =>
      '${_normalizeArtist(artist)}|${_normalizeTitle(title)}';

  RecommendedTrack copyWith({String? imageUrl}) => RecommendedTrack(
        title: title,
        artist: artist,
        imageUrl: imageUrl ?? this.imageUrl,
        match: match,
        mbid: mbid,
      );
}

String _normalizeArtist(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _normalizeTitle(String value) {
  var normalized = value.toLowerCase().trim();

  normalized = normalized.replaceAll(
    RegExp(r'\.(opus|mp3|m4a|wav|flac|aac)$'),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(r'\((feat|ft|featuring)[^)]*\)'),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(r'\[(feat|ft|featuring)[^\]]*\]'),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(r'\s*[-–|]\s*(feat|ft|featuring).*$'),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\s*[-–|]\s*(official|audio|video|lyrics|lyric video|visualizer|remaster(ed)?|live).*$',
    ),
    '',
  );
  normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

  return normalized;
}

class RecommendationException implements Exception {
  const RecommendationException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
