import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final spotifyImportServiceProvider = Provider<SpotifyImportService>((ref) {
  final service = SpotifyImportService();
  ref.onDispose(service.dispose);
  return service;
});

class SpotifyImportException implements Exception {
  const SpotifyImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SpotifyImportTrack {
  const SpotifyImportTrack({
    required this.thumbnailUrl,
    required this.songName,
    required this.artistName,
  });

  final String thumbnailUrl;
  final String songName;
  final String artistName;

  factory SpotifyImportTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyImportTrack(
      thumbnailUrl: (json['thumbnail_url'] as String?)?.trim() ?? '',
      songName: (json['song_name'] as String?)?.trim() ?? 'Unknown title',
      artistName: (json['artist_name'] as String?)?.trim() ?? 'Unknown artist',
    );
  }
}

class SpotifyImportService {
  SpotifyImportService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://spotify-api-beta-vert.vercel.app/';
  final http.Client _client;

  Future<List<SpotifyImportTrack>> importPlaylist(
    String spotifyUrl, {
    String market = 'US',
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'url': spotifyUrl,
        'market': market,
      },
    );

    late http.Response response;
    try {
      response = await _client.get(uri);
    } catch (_) {
      throw const SpotifyImportException(
        'Unable to reach the Spotify import service right now.',
      );
    }

    if (response.statusCode != 200) {
      throw SpotifyImportException(
        'Spotify import failed with status ${response.statusCode}.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const SpotifyImportException(
        'Spotify import returned an invalid response.',
      );
    }

    if (decoded is! List) {
      throw const SpotifyImportException(
        'Spotify import returned an unexpected response.',
      );
    }

    final tracks = decoded
        .whereType<Map>()
        .map((track) => SpotifyImportTrack.fromJson(Map<String, dynamic>.from(track)))
        .where((track) => track.songName.isNotEmpty && track.artistName.isNotEmpty)
        .toList(growable: false);

    if (tracks.isEmpty) {
      throw const SpotifyImportException(
        'No songs were returned for this Spotify playlist.',
      );
    }

    return tracks;
  }

  void dispose() {
    _client.close();
  }
}
