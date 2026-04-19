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
