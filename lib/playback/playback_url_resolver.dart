import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/youtube_service.dart';
import '../library/library_provider.dart';
import 'playback_error_mapper.dart';
import 'playback_models.dart';

class ResolvedMedia {
  const ResolvedMedia({
    required this.realYoutubeId,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  final String realYoutubeId;
  final String videoUrl;

  /// YouTube thumbnail discovered during search. Used as a fallback when
  /// iTunes artwork enrichment doesn't produce a result.
  final String? thumbnailUrl;
}

class PlaybackUrlResolver {
  static const MethodChannel _extractChannel =
      MethodChannel('audiodockr/extract');

  const PlaybackUrlResolver({
    required YoutubeService youtubeService,
    required LibraryNotifier libraryNotifier,
  })  : _youtubeService = youtubeService,
        _libraryNotifier = libraryNotifier;

  final YoutubeService _youtubeService;
  final LibraryNotifier _libraryNotifier;

  static Map<String, String> buildPlaybackHeaders() {
    return const {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
      'Referer': 'https://music.youtube.com/',
      'Origin': 'https://music.youtube.com',
      'Accept-Language': 'en-US,en;q=0.9',
    };
  }

  static Future<void> ensurePlaybackPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final status = await Permission.notification.status;
    if (status.isDenied) {
      final requested = await Permission.notification.request();
      if (!requested.isGranted) {
        throw const PlaybackFailure(
          'notification_permission_denied',
          'Notification permission is required for background playback on Android.',
        );
      }
    }
  }

  Future<String?> extractTrackUrl(String videoId, String videoUrl) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return await _extractChannel.invokeMethod<String>(
          'extract',
          {'videoId': videoId, 'videoUrl': videoUrl},
        );
      }

      return await _youtubeService.extractAudioUrl(
        videoId: videoId,
        videoUrl: videoUrl,
      );
    } on PlatformException catch (error) {
      throw PlaybackFailure(
        error.code,
        error.message ?? 'Unable to prepare audio playback for this track.',
      );
    } on YoutubeServiceException catch (error) {
      throw PlaybackErrorMapper.fromExtractError(error);
    }
  }

  Future<ResolvedMedia> resolveVideoUrlIfNeeded({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
  }) async {
    if (videoUrl.isNotEmpty) {
      return ResolvedMedia(
        realYoutubeId: _extractRealYoutubeId(videoId, videoUrl),
        videoUrl: videoUrl,
      );
    }

    try {
      final query = '$title $artist'.trim();
      final results = await _youtubeService.search(query);
      final match = results.first;
      await _libraryNotifier.updateTrackVideoUrl(
        videoId: videoId,
        videoUrl: match.url,
      );
      return ResolvedMedia(
        realYoutubeId: match.id,
        videoUrl: match.url,
        thumbnailUrl: match.thumbnailUrl,
      );
    } on YoutubeServiceException catch (error) {
      throw PlaybackErrorMapper.fromSearchError(error);
    }
  }

  Future<QueuedTrack> resolveQueuedTrackIfNeeded(QueuedTrack track) async {
    var resolvedVideoUrl = track.videoUrl;

    if (resolvedVideoUrl.isEmpty) {
      final storedTrack = _libraryNotifier.trackById(track.videoId);
      if (storedTrack != null && storedTrack.videoUrl.isNotEmpty) {
        resolvedVideoUrl = storedTrack.videoUrl;
      }
    }

    final resolvedMedia = await resolveVideoUrlIfNeeded(
      videoId: track.videoId,
      videoUrl: resolvedVideoUrl,
      title: track.title,
      artist: track.artist,
    );

    // Use the YouTube thumbnail as a fallback when the track has no artwork
    // (e.g. iTunes enrichment didn't find a match for a recommendation).
    final needsThumbnail = track.thumbnailUrl.isEmpty &&
        resolvedMedia.thumbnailUrl != null &&
        resolvedMedia.thumbnailUrl!.isNotEmpty;

    if (resolvedMedia.videoUrl == track.videoUrl && !needsThumbnail) {
      return track;
    }

    return track.copyWith(
      videoUrl: resolvedMedia.videoUrl,
      thumbnailUrl: needsThumbnail ? resolvedMedia.thumbnailUrl : null,
    );
  }

  static String _extractRealYoutubeId(String originalId, String videoUrl) {
    if (videoUrl.isEmpty) return originalId;

    final uri = Uri.tryParse(videoUrl);
    final queryId = uri?.queryParameters['v'];
    if (queryId != null && queryId.isNotEmpty) return queryId;

    final segments = uri?.pathSegments ?? const <String>[];
    if (segments.isNotEmpty && uri?.host.contains('youtu.be') == true) {
      return segments.first;
    }

    // Handle youtube recommendation where the videoUrl is the actual video ID
    if (originalId.startsWith('yt_rec_') && !videoUrl.contains('http')) {
      return videoUrl;
    }

    return originalId;
  }
}
