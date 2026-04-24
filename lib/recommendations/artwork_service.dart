import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final artworkServiceProvider = Provider<ArtworkService>((ref) {
  final service = ArtworkService();
  ref.onDispose(service.dispose);
  return service;
});

/// Fetches album artwork for a given artist + title via the iTunes Search API.
/// Public, no auth required.
class ArtworkService {
  ArtworkService({http.Client? client}) : _client = client ?? http.Client();

  // Keep concurrency low on mobile to avoid saturating the connection.
  static const int _concurrency = 4;
  static const String _baseUrl = 'https://itunes.apple.com/search';
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 2;

  final http.Client _client;

  /// Look up artwork for a single track. Returns the URL or empty string.
  /// Retries once on failure for resilience on flaky mobile connections.
  Future<String> fetchArtwork({
    required String artist,
    required String title,
  }) async {
    final term = '${artist.trim()} ${title.trim()}'.trim();
    if (term.isEmpty) return '';

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'term': term,
      'media': 'music',
      'limit': '1',
    });

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(_timeout);

        if (response.statusCode == 403 || response.statusCode == 429) {
          // Rate-limited — wait briefly then retry.
          await Future<void>.delayed(const Duration(milliseconds: 500));
          continue;
        }
        if (response.statusCode != 200) return '';

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) return '';

        final results = decoded['results'];
        if (results is! List || results.isEmpty) return '';

        final first = results[0];
        if (first is! Map<String, dynamic>) return '';

        final url = first['artworkUrl100'] as String? ?? '';
        if (url.isEmpty) return '';

        // Scale up from 100x100 to 300x300 for better quality.
        return url.replaceFirst('100x100bb', '300x300bb');
      } catch (_) {
        if (attempt < _maxRetries - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
      }
    }
    return '';
  }

  /// Batch-enrich a list of tracks with iTunes artwork. Every track is
  /// looked up — any existing thumbnail (e.g. Last.fm's star placeholder)
  /// is replaced when iTunes returns a result. If iTunes has no match for
  /// a track, its original imageUrl is kept as-is.
  ///
  /// Returns a new list with the same order and length.
  Future<List<T>> enrichArtwork<T>({
    required List<T> tracks,
    required String Function(T) getArtist,
    required String Function(T) getTitle,
    required T Function(T track, String artworkUrl) withImageUrl,
  }) async {
    final results = List<T>.from(tracks);

    for (var i = 0; i < tracks.length; i += _concurrency) {
      final end = (i + _concurrency < tracks.length)
          ? i + _concurrency
          : tracks.length;
      final chunk = List.generate(end - i, (j) => i + j);
      final urls = await Future.wait(
        chunk.map((idx) => fetchArtwork(
              artist: getArtist(tracks[idx]),
              title: getTitle(tracks[idx]),
            )),
      );
      for (var j = 0; j < chunk.length; j++) {
        if (urls[j].isNotEmpty) {
          results[chunk[j]] = withImageUrl(tracks[chunk[j]], urls[j]);
        }
      }
    }

    return results;
  }

  void dispose() {
    _client.close();
  }
}
