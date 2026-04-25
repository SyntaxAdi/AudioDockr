import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

final youtubeServiceProvider = Provider<YoutubeService>((ref) {
  final service = YoutubeService();
  ref.onDispose(service.dispose);
  return service;
});

class YoutubeServiceException implements Exception {
  const YoutubeServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class YoutubeSearchItem {
  const YoutubeSearchItem({
    required this.id,
    required this.url,
    required this.title,
    required this.uploader,
    required this.duration,
    required this.lowThumbnailUrl,
    required this.mediumThumbnailUrl,
    required this.highThumbnailUrl,
  });

  final String id;
  final String url;
  final String title;
  final String uploader;
  final Duration duration;
  final String lowThumbnailUrl;
  final String mediumThumbnailUrl;
  final String highThumbnailUrl;

  String get thumbnailUrl => highThumbnailUrl;
}

class YoutubeService {
  YoutubeService({YoutubeExplode? client})
      : _client = client ?? YoutubeExplode();

  final YoutubeExplode _client;
  static const Duration maxRecommendationDuration = Duration(minutes: 8);

  static const Set<String> _blockedAutoplayKeywords = {
    '1 hour',
    'advertisement',
    'commercial',
    'extended',
    'karaoke',
    'nightcore',
    'paid promotion',
    'promo',
    'promoted',
    'slowed',
    'slowed reverb',
    'sponsor',
    'sponsored',
    'sped up',
    'speed up',
    'translation',
    'translated',
    'terjemahan',
  };

  static const Set<String> _deprioritizedAutoplayKeywords = {
    'interview',
    'podcast',
    'reaction',
    'review',
    'shorts',
    'teaser',
    'trailer',
  };

  Future<List<YoutubeSearchItem>> search(String query) async {
    try {
      final results = await _client.search.search(query);
      final items = results
          .map(
            (video) => YoutubeSearchItem(
              id: video.id.value,
              url: video.url,
              title: video.title,
              uploader: video.author,
              duration: video.duration ?? Duration.zero,
              lowThumbnailUrl: video.thumbnails.lowResUrl,
              mediumThumbnailUrl: video.thumbnails.mediumResUrl,
              highThumbnailUrl: video.thumbnails.highResUrl,
            ),
          )
          .where((item) => item.id.isNotEmpty && item.url.isNotEmpty)
          .toList();

      if (items.isEmpty) {
        throw const YoutubeServiceException(
          'no_results',
          'No matching songs were found on YouTube.',
        );
      }

      return items;
    } on RequestLimitExceededException {
      throw const YoutubeServiceException(
        'rate_limited',
        'YouTube is rate limiting requests right now. Please try again later.',
      );
    } on SearchItemSectionException {
      throw const YoutubeServiceException(
        'unsupported_response',
        'YouTube returned a response this app could not parse.',
      );
    } on TransientFailureException {
      throw const YoutubeServiceException(
        'temporary_unavailable',
        'YouTube is temporarily unavailable. Please try again in a moment.',
      );
    } on YoutubeExplodeException catch (error) {
      throw YoutubeServiceException(
        'search_failed',
        error.message,
      );
    } catch (_) {
      throw const YoutubeServiceException(
        'search_failed',
        'Search failed. Please try again.',
      );
    }
  }

  static List<YoutubeSearchItem> rankAutoplayCandidates(
    Iterable<YoutubeSearchItem> items, {
    String? title,
    String? artist,
    Duration? maxDuration,
  }) {
    final desiredTitle = _normalizeForMatch(title ?? '');
    final desiredArtist = _normalizeForMatch(artist ?? '');

    final ranked = items
        .where((item) => item.id.isNotEmpty && item.url.isNotEmpty)
        .map(
          (item) => (
            item: item,
            score: _scoreAutoplayCandidate(
              item,
              desiredTitle: desiredTitle,
              desiredArtist: desiredArtist,
              maxDuration: maxDuration,
            ),
          ),
        )
        .where((entry) => entry.score > -1000)
        .toList(growable: false);

    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked.map((entry) => entry.item).toList(growable: false);
  }

  static YoutubeSearchItem? selectAutoplayCandidate(
    Iterable<YoutubeSearchItem> items, {
    String? title,
    String? artist,
    Duration? maxDuration,
  }) {
    final ranked = rankAutoplayCandidates(
      items,
      title: title,
      artist: artist,
      maxDuration: maxDuration,
    );
    return ranked.isEmpty ? null : ranked.first;
  }

  static int _scoreAutoplayCandidate(
    YoutubeSearchItem item, {
    required String desiredTitle,
    required String desiredArtist,
    Duration? maxDuration,
  }) {
    final normalizedTitle = _normalizeForMatch(item.title);
    final normalizedUploader = _normalizeForMatch(item.uploader);
    final normalizedCombined =
        _normalizeForMatch('${item.title} ${item.uploader}');

    if (_containsBlockedAutoplayKeyword(normalizedCombined)) {
      return -1000;
    }

    var score = 0;
    final seconds = item.duration.inSeconds;

    if (maxDuration != null && seconds > 0 && seconds > maxDuration.inSeconds) {
      return -1000;
    }

    if (seconds == 0) {
      score -= 8;
    } else if (seconds < 45) {
      score -= 30;
    } else if (seconds <= 900) {
      score += 12;
      if (seconds >= 90 && seconds <= 600) {
        score += 8;
      }
    } else {
      score -= 6;
    }

    if (desiredTitle.isNotEmpty) {
      if (normalizedTitle.contains(desiredTitle)) {
        score += 40;
      } else {
        score += _tokenOverlap(normalizedTitle, desiredTitle) * 6;
      }
    }

    if (desiredArtist.isNotEmpty) {
      if (normalizedCombined.contains(desiredArtist)) {
        score += 30;
      } else {
        score += _tokenOverlap(normalizedCombined, desiredArtist) * 5;
      }
    }

    if (normalizedCombined.contains('official audio')) score += 10;
    if (normalizedUploader.contains('topic')) score += 8;
    if (normalizedCombined.contains('lyrics')) score += 4;
    if (_containsDeprioritizedAutoplayKeyword(normalizedCombined)) score -= 12;

    return score;
  }

  static bool _containsBlockedAutoplayKeyword(String normalizedText) {
    return _blockedAutoplayKeywords.any(normalizedText.contains);
  }

  static bool _containsDeprioritizedAutoplayKeyword(String normalizedText) {
    return _deprioritizedAutoplayKeywords.any(normalizedText.contains);
  }

  static int _tokenOverlap(String normalizedText, String normalizedNeedle) {
    if (normalizedText.isEmpty || normalizedNeedle.isEmpty) return 0;
    final haystack = normalizedText.split(' ').where((part) => part.isNotEmpty);
    final needle = normalizedNeedle.split(' ').where((part) => part.isNotEmpty);
    final haystackSet = haystack.toSet();
    return needle.where(haystackSet.contains).length;
  }

  static String _normalizeForMatch(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<List<YoutubeSearchItem>> getRelatedVideos(String videoId) async {
    try {
      final video = await _client.videos.get(videoId);
      final related = await _client.videos.getRelatedVideos(video);

      if (related == null) return const [];

      return related
          .map(
            (video) => YoutubeSearchItem(
              id: video.id.value,
              url: video.url,
              title: video.title,
              uploader: video.author,
              duration: video.duration ?? Duration.zero,
              lowThumbnailUrl: video.thumbnails.lowResUrl,
              mediumThumbnailUrl: video.thumbnails.mediumResUrl,
              highThumbnailUrl: video.thumbnails.highResUrl,
            ),
          )
          .where((item) => item.id.isNotEmpty && item.url.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String> extractAudioUrl({
    required String videoId,
    required String videoUrl,
  }) async {
    try {
      final target = videoUrl.isNotEmpty ? videoUrl : videoId;
      final manifest = await _client.videos.streams.getManifest(
        target,
        ytClients: [
          YoutubeApiClient.ios,
          YoutubeApiClient.safari,
          YoutubeApiClient.tv,
        ],
      );

      final audioOnly = manifest.audioOnly;
      if (audioOnly.isNotEmpty) {
        return audioOnly.withHighestBitrate().url.toString();
      }

      final muxed = manifest.muxed;
      if (muxed.isNotEmpty) {
        return muxed.withHighestBitrate().url.toString();
      }

      throw const YoutubeServiceException(
        'extract_failed',
        'Unable to prepare audio playback for this track.',
      );
    } on RequestLimitExceededException {
      throw const YoutubeServiceException(
        'rate_limited',
        'YouTube is rate limiting playback requests right now. Try again soon.',
      );
    } on VideoUnplayableException catch (error) {
      throw YoutubeServiceException(
        'extract_failed',
        error.message,
      );
    } on TransientFailureException {
      throw const YoutubeServiceException(
        'temporary_unavailable',
        'YouTube is temporarily unavailable. Please try again soon.',
      );
    } on YoutubeExplodeException catch (error) {
      throw YoutubeServiceException(
        'unsupported_response',
        error.message,
      );
    } catch (_) {
      throw const YoutubeServiceException(
        'extract_failed',
        'Unable to prepare audio playback for this track.',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
