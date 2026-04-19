import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'playlist_import_models.dart';

final youtubePlaylistImportServiceProvider =
    Provider<YoutubePlaylistImportService>((ref) {
  final service = YoutubePlaylistImportService();
  ref.onDispose(service.dispose);
  return service;
});

class YoutubePlaylistImportService {
  YoutubePlaylistImportService({http.Client? client})
      : _client = client ?? http.Client();

  static const String _baseUrl = 'https://spotify-api-beta-vert.vercel.app/';
  final http.Client _client;

  Future<List<PlaylistImportTrack>> importPlaylist(String youtubeUrl) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'url': youtubeUrl,
      },
    );

    late http.Response response;
    try {
      response = await _client.get(uri);
    } catch (_) {
      throw const PlaylistImportException(
        'Unable to reach YouTube import service right now.',
      );
    }

    if (response.statusCode != 200) {
      throw PlaylistImportException(
        'YouTube import failed with status ${response.statusCode}.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const PlaylistImportException(
        'YouTube import returned invalid response.',
      );
    }

    if (decoded is! List) {
      throw const PlaylistImportException(
        'YouTube import returned unexpected response.',
      );
    }

    final tracks = decoded
        .whereType<Map>()
        .map((track) => Map<String, dynamic>.from(track))
        .map(
          (track) => PlaylistImportTrack(
            thumbnailUrl: (track['thumbnail_url'] as String?)?.trim() ?? '',
            songName:
                (track['video_title'] as String?)?.trim() ?? 'Unknown title',
            artistName:
                (track['channel_name'] as String?)?.trim() ?? 'Unknown artist',
            videoUrl: (track['video_url'] as String?)?.trim() ?? '',
          ),
        )
        .where((track) =>
            track.songName.isNotEmpty &&
            track.artistName.isNotEmpty &&
            track.videoUrl.isNotEmpty)
        .toList(growable: false);

    if (tracks.isEmpty) {
      throw const PlaylistImportException(
        'No songs were returned for this YouTube playlist.',
      );
    }

    return tracks;
  }

  void dispose() {
    _client.close();
  }
}
