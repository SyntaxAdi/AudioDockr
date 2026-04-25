import '../api/youtube_service.dart';

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

  String get dedupKey => dedupKeyFor(
        artist: artist,
        title: title,
      );

  static String dedupKeyFor({
    required String artist,
    required String title,
  }) {
    return '${_normalizeArtist(artist)}|${_normalizeTitle(title)}';
  }

  static String normalizedTitleFor(String title) {
    return _normalizeTitle(title);
  }

  static String normalizedArtistFor(String artist) {
    return _normalizeArtist(artist);
  }

  RecommendedTrack copyWith({String? imageUrl}) => RecommendedTrack(
        title: title,
        artist: artist,
        imageUrl: imageUrl ?? this.imageUrl,
        match: match,
        mbid: mbid,
      );

  factory RecommendedTrack.fromYoutubeSearchItem(
    YoutubeSearchItem item, {
    String? fallbackArtist,
  }) {
    final metadata = _inferYoutubeMetadata(
      item.title,
      uploader: item.uploader,
      fallbackArtist: fallbackArtist,
    );
    return RecommendedTrack(
      title: metadata.title,
      artist: metadata.artist,
      imageUrl: item.thumbnailUrl,
    );
  }
}

({String title, String artist}) _inferYoutubeMetadata(
  String rawTitle, {
  required String uploader,
  String? fallbackArtist,
}) {
  final cleanedUploader = _cleanUploader(uploader);
  var title = rawTitle.trim();
  var artist = cleanedUploader.isNotEmpty ? cleanedUploader : uploader.trim();

  for (final separator in const [' - ', ' – ', ' — ', ' | ', ': ']) {
    final index = title.indexOf(separator);
    if (index <= 0) continue;

    final lhs = title.substring(0, index).trim();
    final rhs = title.substring(index + separator.length).trim();
    if (lhs.isEmpty || rhs.isEmpty) continue;

    final cleanedLhs = _cleanRecommendationTitle(lhs);
    final cleanedRhs = _cleanRecommendationTitle(rhs);
    if (cleanedLhs.isEmpty || cleanedRhs.isEmpty) continue;

    artist = lhs;
    title = rhs;
    break;
  }

  final normalizedFallbackArtist = _normalizeArtist(fallbackArtist ?? '');
  final normalizedArtist = _normalizeArtist(artist);
  final normalizedTitle = _normalizeTitle(title);

  if (normalizedArtist.isEmpty &&
      normalizedFallbackArtist.isNotEmpty &&
      normalizedTitle.isNotEmpty) {
    artist = fallbackArtist!.trim();
  }

  return (
    title: _cleanRecommendationTitle(title),
    artist: artist.trim(),
  );
}

String _cleanUploader(String value) {
  return value
      .replaceAll(RegExp(r'\s*-\s*topic$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s*official\s*$', caseSensitive: false), '')
      .trim();
}

String _cleanRecommendationTitle(String value) {
  var normalized = value.trim();
  normalized = normalized.replaceAll(
    RegExp(
      r'\s*[\[(](official|audio|video|lyrics|lyric video|lirik|visualizer|remaster(ed)?|live|sped up( version)?|speed up( version)?|slowed( reverb)?|nightcore|karaoke|translation|translated|terjemahan|[0-9]+\s*hour(\s*version)?)[^)\]]*[\])]',
      caseSensitive: false,
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\s*[-–|/]\s*(official|audio|video|lyrics|lyric video|lirik|visualizer|remaster(ed)?|live|sped up( version)?|speed up( version)?|slowed( reverb)?|nightcore|karaoke|translation|translated|terjemahan|[0-9]+\s*hour(\s*version)?).*$',
      caseSensitive: false,
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\b[0-9]+\s*hour(\s*version)?\b',
      caseSensitive: false,
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\b[0-9]+\s*min(ute)?s?(\s*version)?\b',
      caseSensitive: false,
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\b(edit audio|edit|vibes|lirik|sped up|speed up|slowed( reverb)?|nightcore|karaoke|translation|translated|terjemahan)\b',
      caseSensitive: false,
    ),
    '',
  );
  return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
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
    RegExp(
      r'\((official|audio|video|lyrics|lyric video|lirik|visualizer|remaster(ed)?|live|sped up( version)?|speed up( version)?|slowed( reverb)?|nightcore|karaoke|translation|translated|terjemahan|[0-9]+\s*hour(\s*version)?)[^)]*\)',
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\[(official|audio|video|lyrics|lyric video|lirik|visualizer|remaster(ed)?|live|sped up( version)?|speed up( version)?|slowed( reverb)?|nightcore|karaoke|translation|translated|terjemahan|[0-9]+\s*hour(\s*version)?)[^\]]*\]',
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(r'\s*[-–|]\s*(feat|ft|featuring).*$'),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\s*[-–|/]\s*(official|audio|video|lyrics|lyric video|lirik|visualizer|remaster(ed)?|live|sped up( version)?|speed up( version)?|slowed( reverb)?|nightcore|karaoke|translation|translated|terjemahan|[0-9]+\s*hour(\s*version)?).*$',
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\s*[\[(](lirik|sped up( version)?|speed up( version)?|slowed( reverb)?|nightcore|karaoke|translation|translated|terjemahan|[0-9]+\s*hour(\s*version)?)[^)\]]*[\])]',
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\b[0-9]+\s*hour(\s*version)?\b',
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\b[0-9]+\s*min(ute)?s?(\s*version)?\b',
    ),
    '',
  );
  normalized = normalized.replaceAll(
    RegExp(
      r'\b(edit audio|edit|vibes|lirik|sped up|speed up|slowed|reverb|nightcore|karaoke|translation|translated|terjemahan)\b',
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
