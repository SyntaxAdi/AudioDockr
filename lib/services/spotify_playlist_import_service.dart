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

  static const _supportedTypes = {'track', 'playlist'};
  static const int _enrichConcurrency = 8;

  final http.Client _client;

  Future<List<PlaylistImportTrack>> importPlaylist(
    String spotifyUrl, {
    String market = 'US',
  }) async {
    final parsed = _parseSpotifyUrl(spotifyUrl);

    if (parsed.type == 'track') {
      final oembed = await _fetchOEmbed(spotifyUrl);
      final track = _extractTrackMetadata(oembed);
      return [track];
    }

    final html = await _fetchEmbedPage(parsed.id);
    final rawTracks = _extractPlaylistTracks(html);
    return _enrichTracks(rawTracks);
  }

  // ─── URL parsing ──────────────────────────────────────────────────

  static ({String type, String id}) _parseSpotifyUrl(String input) {
    final uri = Uri.tryParse(input);
    if (uri == null) {
      throw const PlaylistImportException('Not a valid Spotify URL.');
    }

    final host = uri.host;
    if (host != 'open.spotify.com' && host != 'play.spotify.com') {
      throw const PlaylistImportException(
        'Only Spotify track and playlist URLs are supported.',
      );
    }

    final segments = uri.pathSegments;
    if (segments.length < 2 || !_supportedTypes.contains(segments[0])) {
      throw const PlaylistImportException(
        'Only Spotify track and playlist URLs are supported.',
      );
    }

    return (type: segments[0], id: segments[1]);
  }

  // ─── Spotify oEmbed ───────────────────────────────────────────────

  Future<Map<String, dynamic>> _fetchOEmbed(String spotifyUrl) async {
    final uri = Uri.parse(
      'https://open.spotify.com/oembed?url=${Uri.encodeComponent(spotifyUrl)}',
    );

    final http.Response response;
    try {
      response = await _client.get(uri, headers: {'Accept': 'application/json'});
    } catch (_) {
      throw const PlaylistImportException(
        'Unable to reach Spotify right now.',
      );
    }

    if (response.statusCode != 200) {
      throw PlaylistImportException(
        'Spotify oEmbed request failed (${response.statusCode}).',
      );
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const PlaylistImportException(
        'Spotify returned an invalid oEmbed response.',
      );
    }
  }

  static PlaylistImportTrack _extractTrackMetadata(Map<String, dynamic> oembed) {
    final title = _clean(oembed['title'] as String? ?? '');
    final artist = _clean(oembed['author_name'] as String? ?? '');
    final thumbnail = oembed['thumbnail_url'] as String? ?? '';

    if (title.isEmpty) {
      throw const PlaylistImportException(
        'Could not read metadata from Spotify.',
      );
    }

    return PlaylistImportTrack(
      thumbnailUrl: thumbnail,
      songName: title,
      artistName: artist,
    );
  }

  // ─── Embed page scraping (playlists) ──────────────────────────────

  Future<String> _fetchEmbedPage(String playlistId) async {
    final uri = Uri.parse(
      'https://open.spotify.com/embed/playlist/'
      '${Uri.encodeComponent(playlistId)}?utm_source=oembed',
    );

    final http.Response response;
    try {
      response = await _client.get(uri, headers: {'Accept': 'text/html'});
    } catch (_) {
      throw const PlaylistImportException(
        'Unable to reach Spotify right now.',
      );
    }

    if (response.statusCode != 200) {
      throw PlaylistImportException(
        'Spotify embed page request failed (${response.statusCode}).',
      );
    }

    return response.body;
  }

  static List<_RawTrack> _extractPlaylistTracks(String html) {
    final match = RegExp(
      r'<script id="__NEXT_DATA__" type="application/json">([\s\S]*?)</script>',
      caseSensitive: false,
    ).firstMatch(html);

    if (match == null) {
      throw const PlaylistImportException(
        'Could not locate playlist data in the Spotify embed page.',
      );
    }

    final Map<String, dynamic> nextData;
    try {
      nextData = jsonDecode(match.group(1)!) as Map<String, dynamic>;
    } catch (_) {
      throw const PlaylistImportException(
        'Could not parse playlist data from the Spotify embed page.',
      );
    }

    final rawTrackList = (nextData['props'] as Map<String, dynamic>?)?['pageProps']
        ?['state']?['data']?['entity']?['trackList'];

    final List<dynamic> rawTracks;
    if (rawTrackList is List) {
      rawTracks = rawTrackList;
    } else if (rawTrackList is Map) {
      rawTracks = rawTrackList.values.toList();
    } else {
      throw const PlaylistImportException(
        'Could not read tracks from the Spotify playlist embed.',
      );
    }

    if (rawTracks.isEmpty) {
      throw const PlaylistImportException(
        'Could not read tracks from the Spotify playlist embed.',
      );
    }

    final tracks = <_RawTrack>[];
    for (final entry in rawTracks) {
      if (entry is! Map<String, dynamic>) continue;
      if (entry['entityType'] != 'track') continue;
      final uri = entry['uri'] as String?;
      if (uri == null) continue;

      final trackId = _extractTrackIdFromUri(uri);
      final songName = _clean(entry['title'] as String? ?? '');
      if (trackId.isEmpty || songName.isEmpty) continue;

      tracks.add(_RawTrack(
        trackId: trackId,
        songName: songName,
        artistName: _clean(entry['subtitle'] as String? ?? ''),
      ));
    }

    if (tracks.isEmpty) {
      throw const PlaylistImportException(
        'No songs were found in this Spotify playlist.',
      );
    }

    return tracks;
  }

  static String _extractTrackIdFromUri(String uri) {
    final match = RegExp(r'^spotify:track:([A-Za-z0-9]+)$').firstMatch(uri);
    return match?.group(1) ?? '';
  }

  // ─── Thumbnail enrichment via oEmbed ──────────────────────────────

  Future<List<PlaylistImportTrack>> _enrichTracks(List<_RawTrack> raw) async {
    final results = <PlaylistImportTrack>[];

    for (var i = 0; i < raw.length; i += _enrichConcurrency) {
      final chunk = raw.skip(i).take(_enrichConcurrency);
      final enriched = await Future.wait(chunk.map(_enrichSingleTrack));
      results.addAll(enriched);
    }

    if (results.isEmpty) {
      throw const PlaylistImportException(
        'No songs were returned for this Spotify playlist.',
      );
    }

    return results;
  }

  Future<PlaylistImportTrack> _enrichSingleTrack(_RawTrack track) async {
    final spotifyUrl = 'https://open.spotify.com/track/${track.trackId}';

    String thumbnailUrl = '';
    try {
      final oembed = await _fetchOEmbed(spotifyUrl);
      thumbnailUrl = oembed['thumbnail_url'] as String? ?? '';
    } catch (_) {
      // oEmbed enrichment is best-effort; proceed without thumbnail.
    }

    return PlaylistImportTrack(
      thumbnailUrl: thumbnailUrl,
      songName: track.songName,
      artistName: track.artistName,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  static String _clean(String value) {
    return _decodeHtmlEntities(value).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _decodeHtmlEntities(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  void dispose() {
    _client.close();
  }
}

class _RawTrack {
  const _RawTrack({
    required this.trackId,
    required this.songName,
    required this.artistName,
  });

  final String trackId;
  final String songName;
  final String artistName;
}
