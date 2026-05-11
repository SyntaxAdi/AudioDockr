import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/jiosaavn_service.dart';
import '../api/youtube_service.dart';
import '../library/library_provider.dart';
import '../settings/app_preferences.dart';
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

// ── Audio-source adapter interface ─────────────────────────────────────────
//
// Each audio engine implements this interface. To add a new engine:
//   1. Add an enum value to AudioSource in app_preferences.dart.
//   2. Create a class that extends _AudioSourceAdapter here.
//   3. Register it in PlaybackUrlResolver._adapters below.
//   Nothing else needs to change.

abstract class _AudioSourceAdapter {
  /// Search for [title] + [artist] and return a resolved media object,
  /// or null if no suitable match was found.
  ///
  /// [trackId] is the original synthetic ID (e.g. `lastfm_rec_0`) and is
  /// forwarded to adapters that need extra context (e.g. max-duration hints).
  Future<ResolvedMedia?> findTrack({
    required String title,
    required String artist,
    required String trackId,
  });
}

class _YouTubeAdapter extends _AudioSourceAdapter {
  _YouTubeAdapter({
    required YoutubeService youtubeService,
    required LibraryNotifier libraryNotifier,
  })  : _youtubeService = youtubeService,
        _libraryNotifier = libraryNotifier;

  final YoutubeService _youtubeService;
  final LibraryNotifier _libraryNotifier;

  static const String _lastFmPrefix = 'lastfm_rec_';

  @override
  Future<ResolvedMedia?> findTrack({
    required String title,
    required String artist,
    required String trackId,
  }) async {
    final query = '$title $artist'.trim();
    try {
      final results = await _youtubeService.search(query);
      final maxDuration = trackId.startsWith(_lastFmPrefix)
          ? YoutubeService.maxRecommendationDuration
          : null;
      final match = YoutubeService.selectAutoplayCandidate(
        results,
        title: title,
        artist: artist,
        maxDuration: maxDuration,
      );
      if (match == null) return null;
      await _libraryNotifier.updateTrackVideoUrl(
        videoId: trackId,
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
}

class _JioSaavnAdapter extends _AudioSourceAdapter {
  _JioSaavnAdapter(this._jiosaavnService);

  final JioSaavnService _jiosaavnService;

  @override
  Future<ResolvedMedia?> findTrack({
    required String title,
    required String artist,
    required String trackId,
  }) async {
    try {
      final query = '$title $artist'.trim();
      final results = await _jiosaavnService.search(query, limit: 5);
      if (results.isEmpty) return null;
      final best = results.first;
      return ResolvedMedia(
        realYoutubeId: 'jio_${best.id}',
        videoUrl: '',
        thumbnailUrl: best.highThumbnailUrl,
      );
    } catch (_) {
      return null;
    }
  }
}

// ── Resolver ─────────────────────────────────────────────────────────────────

class PlaybackUrlResolver {
  static const MethodChannel _extractChannel =
      MethodChannel('audiodockr/extract');
  static const String _jioSaavnIdPrefix = 'jio_';

  PlaybackUrlResolver({
    required YoutubeService youtubeService,
    required JioSaavnService jiosaavnService,
    required LibraryNotifier libraryNotifier,
  })  : _youtubeService = youtubeService,
        _jiosaavnService = jiosaavnService,
        _libraryNotifier = libraryNotifier,
        _adapters = {
          AudioSource.youtube: _YouTubeAdapter(
            youtubeService: youtubeService,
            libraryNotifier: libraryNotifier,
          ),
          AudioSource.jioSaavn: _JioSaavnAdapter(jiosaavnService),
        };

  final YoutubeService _youtubeService;
  final JioSaavnService _jiosaavnService;
  final LibraryNotifier _libraryNotifier;
  final Map<AudioSource, _AudioSourceAdapter> _adapters;

  static bool isJioSaavnId(String videoId) =>
      videoId.startsWith(_jioSaavnIdPrefix);

  static String saavnIdFromVideoId(String videoId) =>
      videoId.replaceFirst(_jioSaavnIdPrefix, '');

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
    if (isJioSaavnId(videoId)) {
      final url = await _jiosaavnService.getStreamUrl(saavnIdFromVideoId(videoId));
      if (url == null || url.isEmpty) {
        throw const PlaybackFailure(
          'extract_empty',
          'Could not load JioSaavn stream. Please try again.',
        );
      }
      return url;
    }

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
    if (isJioSaavnId(videoId)) {
      return ResolvedMedia(realYoutubeId: videoId, videoUrl: videoUrl);
    }

    if (videoUrl.isNotEmpty) {
      return ResolvedMedia(
        realYoutubeId: _extractRealYoutubeId(videoId, videoUrl),
        videoUrl: videoUrl,
      );
    }

    final audioSource = await AppPreferences.loadAudioSource();
    final adapter = _adapters[audioSource] ?? _adapters[AudioSource.youtube]!;

    ResolvedMedia? result = await adapter.findTrack(
      title: title,
      artist: artist,
      trackId: videoId,
    );

    // If the selected engine returned nothing, fall back to YouTube so the
    // user never gets a dead silence. Skip if YouTube is already the engine.
    if (result == null && audioSource != AudioSource.youtube) {
      result = await _adapters[AudioSource.youtube]!.findTrack(
        title: title,
        artist: artist,
        trackId: videoId,
      );
    }

    if (result != null) return result;
    throw const PlaybackFailure(
      'no_playable_match',
      'No playable match was found for this track.',
    );
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
