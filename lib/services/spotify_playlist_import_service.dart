import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'playlist_import_models.dart';

final spotifyPlaylistImportServiceProvider =
    Provider<SpotifyPlaylistImportService>((ref) {
  final service = SpotifyPlaylistImportService();
  ref.onDispose(service.dispose);
  return service;
});

class SpotifyPlaylistImportService {
  SpotifyPlaylistImportService({http.Client? client})
      : _client = client ?? http.Client();

  static const String _baseUrl = 'https://spotify-api-beta-vert.vercel.app/';
  final http.Client _client;

  Future<List<PlaylistImportTrack>> importPlaylist(
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
      throw const PlaylistImportException(
        'Unable to reach Spotify import service right now.',
      );
    }

    if (response.statusCode != 200) {
      throw PlaylistImportException(
        'Spotify import failed with status ${response.statusCode}.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const PlaylistImportException(
        'Spotify import returned invalid response.',
      );
    }

    if (decoded is! List) {
      throw const PlaylistImportException(
        'Spotify import returned unexpected response.',
      );
    }

    final tracks = decoded
        .whereType<Map>()
        .map((track) => Map<String, dynamic>.from(track))
        .map(
          (track) => PlaylistImportTrack(
            thumbnailUrl: (track['thumbnail_url'] as String?)?.trim() ?? '',
            songName: (track['song_name'] as String?)?.trim() ?? 'Unknown title',
            artistName:
                (track['artist_name'] as String?)?.trim() ?? 'Unknown artist',
          ),
        )
        .where((track) => track.songName.isNotEmpty && track.artistName.isNotEmpty)
        .toList(growable: false);

    if (tracks.isEmpty) {
      throw const PlaylistImportException(
        'No songs were returned for this Spotify playlist.',
      );
    }

    return tracks;
  }

  void dispose() {
    _client.close();
  }
}
