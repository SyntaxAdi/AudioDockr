import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'recommendation_models.dart';
import 'recommendation_preferences.dart';

/// Result of an API key probe against Last.fm. Separate from the generic
/// rec-fetch path so the Settings UI can tell the user *why* a key didn't
/// work (bad key vs. flaky network) without guessing.
enum LastFmKeyValidation {
  empty,
  valid,
  rejected,
  networkError,
}

final lastFmServiceProvider = Provider<LastFmService>((ref) {
  final service = LastFmService(
    // Resolved on every call so changes to the Last.fm API key in Settings
    // take effect immediately without having to rebuild the service.
    apiKeyResolver: () =>
        ref.read(recommendationPreferencesProvider).apiKey,
  );
  ref.onDispose(service.dispose);
  return service;
});

class LastFmService {
  LastFmService({
    http.Client? client,
    required String Function() apiKeyResolver,
  })  : _client = client ?? http.Client(),
        _apiKeyResolver = apiKeyResolver;

  static const String _baseUrl = 'https://ws.audioscrobbler.com/2.0/';

  final http.Client _client;
  final String Function() _apiKeyResolver;

  String get _apiKey => _apiKeyResolver().trim();

  bool get hasApiKey => _apiKey.isNotEmpty;

  Future<List<RecommendedTrack>> getSimilarTracks({
    required String artist,
    required String title,
    int limit = 5,
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      throw const RecommendationException(
        'Add your Last.fm API key in Settings › Playback › Autoplay recommendations.',
        code: 'missing_api_key',
      );
    }

    // Primary: track-level similar. Last.fm's strongest signal, but it's
    // sparse for long-tail / regional catalogs (Hindi, K-pop, local indie).
    final direct = await _fetchTrackSimilar(
      apiKey: apiKey,
      artist: artist,
      title: title,
      limit: limit,
    );

    if (direct.length >= limit) {
      return direct.take(limit).toList(growable: false);
    }

    // Fallback: artist-level similarity. Merge with direct results instead
    // of replacing them so sparse track matches still contribute.
    final artistFallback = await _fetchArtistFallback(
      apiKey: apiKey,
      seedArtist: artist,
      limit: limit * 2,
    );

    if (artistFallback.isEmpty) return direct;

    final merged = <RecommendedTrack>[];
    final seen = <String>{};

    for (final track in [...direct, ...artistFallback]) {
      if (seen.add(track.dedupKey)) {
        merged.add(track);
      }
      if (merged.length >= limit) break;
    }

    return merged;
  }

  Future<List<RecommendedTrack>> _fetchTrackSimilar({
    required String apiKey,
    required String artist,
    required String title,
    required int limit,
  }) async {
    final decoded = await _getJson({
      'method': 'track.getsimilar',
      'artist': artist,
      'track': title,
      'api_key': apiKey,
      'format': 'json',
      'limit': '$limit',
      'autocorrect': '1',
    });
    if (decoded == null || decoded.containsKey('error')) return const [];

    final similar = decoded['similartracks'];
    if (similar is! Map) return const [];
    final tracks = similar['track'];
    if (tracks is! List) return const [];

    return tracks
        .whereType<Map>()
        .map((raw) => _parseTrack(Map<String, dynamic>.from(raw)))
        .whereType<RecommendedTrack>()
        .toList(growable: false);
  }

  Future<List<RecommendedTrack>> _fetchArtistFallback({
    required String apiKey,
    required String seedArtist,
    required int limit,
  }) async {
    final similarArtists = await _getSimilarArtists(
      apiKey: apiKey,
      artist: seedArtist,
      limit: 6,
    );
    if (similarArtists.isEmpty) return const [];

    // Pull a couple of top tracks from each similar artist in parallel,
    // and swallow per-artist failures so one flaky lookup can't wipe out
    // the whole fallback.
    final batches = await Future.wait(
      similarArtists.map(
        (artist) => _getArtistTopTracks(
          apiKey: apiKey,
          artist: artist,
          limit: 3,
        ).catchError((_) => <RecommendedTrack>[]),
      ),
    );

    final out = <RecommendedTrack>[];
    final seen = <String>{};
    for (final batch in batches) {
      for (final track in batch) {
        if (out.length >= limit) return out;
        if (seen.add(track.dedupKey)) out.add(track);
      }
    }
    return out;
  }

  Future<List<String>> _getSimilarArtists({
    required String apiKey,
    required String artist,
    required int limit,
  }) async {
    final decoded = await _getJson({
      'method': 'artist.getsimilar',
      'artist': artist,
      'api_key': apiKey,
      'format': 'json',
      'limit': '$limit',
      'autocorrect': '1',
    });
    if (decoded == null || decoded.containsKey('error')) return const [];

    final similar = decoded['similarartists'];
    if (similar is! Map) return const [];
    final artists = similar['artist'];
    if (artists is! List) return const [];

    return [
      for (final entry in artists)
        if (entry is Map)
          ((entry['name'] as String?)?.trim() ?? '')
      ,
    ].where((name) => name.isNotEmpty).toList(growable: false);
  }

  Future<List<RecommendedTrack>> _getArtistTopTracks({
    required String apiKey,
    required String artist,
    required int limit,
  }) async {
    final decoded = await _getJson({
      'method': 'artist.gettoptracks',
      'artist': artist,
      'api_key': apiKey,
      'format': 'json',
      'limit': '$limit',
      'autocorrect': '1',
    });
    if (decoded == null || decoded.containsKey('error')) return const [];

    final top = decoded['toptracks'];
    if (top is! Map) return const [];
    final tracks = top['track'];
    if (tracks is! List) return const [];

    return tracks
        .whereType<Map>()
        .map((raw) => _parseTrack(Map<String, dynamic>.from(raw)))
        .whereType<RecommendedTrack>()
        .toList(growable: false);
  }

  /// Shared GET + JSON-decode for the non-validation endpoints. Throws the
  /// same `RecommendationException` variants the original inline code did
  /// so upstream error handling is unchanged.
  Future<Map<String, dynamic>?> _getJson(
    Map<String, String> queryParameters,
  ) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);

    late http.Response response;
    try {
      response = await _client.get(uri);
    } catch (_) {
      throw const RecommendationException(
        'Unable to reach Last.fm right now.',
        code: 'network',
      );
    }

    if (response.statusCode != 200) {
      throw RecommendationException(
        'Last.fm returned HTTP ${response.statusCode}.',
        code: 'http',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const RecommendationException(
        'Last.fm returned invalid JSON.',
        code: 'invalid_response',
      );
    }

    if (decoded is! Map) {
      throw const RecommendationException(
        'Unexpected response format from Last.fm.',
        code: 'invalid_response',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  /// Probes Last.fm with the given key so the Settings page can give the
  /// user immediate feedback. Uses `chart.gettoptracks` because it's one
  /// of the cheapest authenticated endpoints — no seed track required.
  Future<LastFmKeyValidation> validateApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return LastFmKeyValidation.empty;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'method': 'chart.gettoptracks',
      'api_key': trimmed,
      'format': 'json',
      'limit': '1',
    });

    late http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      return LastFmKeyValidation.networkError;
    } catch (_) {
      return LastFmKeyValidation.networkError;
    }

    if (response.statusCode == 403) return LastFmKeyValidation.rejected;
    if (response.statusCode != 200) return LastFmKeyValidation.networkError;

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      return LastFmKeyValidation.networkError;
    }

    if (decoded is Map && decoded.containsKey('error')) {
      // Last.fm error code 10 = "Invalid API key". Any other error is a
      // transient service issue and tells us nothing about the key.
      final code = decoded['error'];
      if (code is int && code == 10) return LastFmKeyValidation.rejected;
      if (code is String && code == '10') return LastFmKeyValidation.rejected;
      return LastFmKeyValidation.networkError;
    }

    return LastFmKeyValidation.valid;
  }

  RecommendedTrack? _parseTrack(Map<String, dynamic> raw) {
    final name = (raw['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;

    final artist = raw['artist'];
    String? artistName;
    if (artist is Map) {
      artistName = (artist['name'] as String?)?.trim();
    } else if (artist is String) {
      artistName = artist.trim();
    }
    if (artistName == null || artistName.isEmpty) return null;

    final match = double.tryParse(raw['match']?.toString() ?? '');
    final mbid = (raw['mbid'] as String?)?.trim();
    final imageUrl = _pickLargestImage(raw['image']);

    return RecommendedTrack(
      title: name,
      artist: artistName,
      imageUrl: imageUrl,
      match: match,
      mbid: (mbid == null || mbid.isEmpty) ? null : mbid,
    );
  }

  /// Last.fm no longer hosts real track artwork. Every track returns the
  /// same generic star placeholder (`2a96cbd8b46e442fc41c2b86b821562f`).
  /// Treat that as empty so downstream code (iTunes enrichment) knows it
  /// still needs to fetch a real thumbnail.
  static const _lastFmPlaceholderHash = '2a96cbd8b46e442fc41c2b86b821562f';

  String _pickLargestImage(Object? images) {
    if (images is! List) return '';
    for (final size in const ['extralarge', 'large', 'medium', 'small']) {
      for (final img in images) {
        if (img is Map &&
            img['size'] == size &&
            img['#text'] is String &&
            (img['#text'] as String).isNotEmpty) {
          final url = img['#text'] as String;
          if (url.contains(_lastFmPlaceholderHash)) return '';
          return url;
        }
      }
    }
    return '';
  }

  void dispose() {
    _client.close();
  }
}
