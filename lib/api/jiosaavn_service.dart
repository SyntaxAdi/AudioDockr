import 'dart:convert';

import 'package:dart_des/dart_des.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final jioSaavnServiceProvider = Provider<JioSaavnService>((ref) {
  final service = JioSaavnService();
  ref.onDispose(service.dispose);
  return service;
});

class JioSaavnServiceException implements Exception {
  const JioSaavnServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class JioSaavnSearchItem {
  const JioSaavnSearchItem({
    required this.id,
    required this.name,
    required this.artist,
    required this.duration,
    required this.lowThumbnailUrl,
    required this.mediumThumbnailUrl,
    required this.highThumbnailUrl,
  });

  final String id;
  final String name;
  final String artist;
  final Duration duration;
  final String lowThumbnailUrl;
  final String mediumThumbnailUrl;
  final String highThumbnailUrl;

  String get thumbnailUrl => highThumbnailUrl;
}

class JioSaavnService {
  static const String _apiBase = 'https://www.jiosaavn.com/api.php';
  static final List<int> _desKey = utf8.encode('38346591');

  JioSaavnService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String? _decryptUrl(String? encrypted) {
    if (encrypted == null || encrypted.isEmpty) return null;
    try {
      final padded = encrypted.length % 4 == 0
          ? encrypted
          : encrypted + ('=' * (4 - encrypted.length % 4));
      final decoded = base64.decode(padded);
      final des = DES(
        key: _desKey,
        mode: DESMode.ECB,
        paddingType: DESPaddingType.PKCS7,
      );
      final decrypted = des.decrypt(decoded);
      final url = utf8
          .decode(decrypted.where((b) => b >= 32 && b < 127).toList())
          .trim();
      return url.isEmpty ? null : url;
    } catch (_) {
      return null;
    }
  }

  static String _decodeHtml(String text) => text
      .replaceAll('&quot;', '"')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&#039;', "'")
      .replaceAll('&apos;', "'");

  static String _upgradeImageQuality(String url, String resolution) => url
      .replaceAll('50x50', resolution)
      .replaceAll('150x150', resolution)
      .replaceAll('250x250', resolution);

  static String _upgradeTo320(String url) =>
      url.replaceAll('_96.mp4', '_320.mp4').replaceAll('_160.mp4', '_320.mp4');

  Future<List<JioSaavnSearchItem>> search(
    String query, {
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(_apiBase).replace(queryParameters: {
        '__call': 'search.getResults',
        'q': query,
        'p': '1',
        'n': '$limit',
        '_format': 'json',
        '_marker': '0',
        'ctx': 'web6dot0',
      });
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw const JioSaavnServiceException(
          'search_failed',
          'JioSaavn search failed. Please try again.',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? const [];

      return results
          .map((raw) => _parseSearchItem(raw as Map<String, dynamic>))
          .whereType<JioSaavnSearchItem>()
          .toList(growable: false);
    } on JioSaavnServiceException {
      rethrow;
    } on http.ClientException {
      throw const JioSaavnServiceException(
        'network_error',
        'JioSaavn search failed. Check your internet connection.',
      );
    } catch (_) {
      throw const JioSaavnServiceException(
        'search_failed',
        'JioSaavn search failed. Please try again.',
      );
    }
  }

  JioSaavnSearchItem? _parseSearchItem(Map<String, dynamic> raw) {
    final id = raw['id'] as String?;
    if (id == null || id.isEmpty) return null;

    final name = _decodeHtml((raw['song'] as String?) ?? 'Unknown title');
    final artist = _decodeHtml(
      (raw['primary_artists'] as String?)?.isNotEmpty == true
          ? raw['primary_artists'] as String
          : (raw['singers'] as String?) ?? 'Unknown',
    );
    final duration =
        Duration(seconds: int.tryParse(raw['duration']?.toString() ?? '') ?? 0);

    final imageRaw = (raw['image'] as String?) ?? '';
    final lowThumb = imageRaw;
    final midThumb = _upgradeImageQuality(imageRaw, '250x250');
    final highThumb = _upgradeImageQuality(imageRaw, '500x500');

    return JioSaavnSearchItem(
      id: id,
      name: name,
      artist: artist,
      duration: duration,
      lowThumbnailUrl: lowThumb,
      mediumThumbnailUrl: midThumb,
      highThumbnailUrl: highThumb,
    );
  }

  Future<String?> getStreamUrl(String songId) async {
    try {
      final uri = Uri.parse(_apiBase).replace(queryParameters: {
        '__call': 'song.getDetails',
        'cc': 'in',
        '_marker': '0',
        '_format': 'json',
        'pids': songId,
      });
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final song = data[songId] as Map<String, dynamic>?;
      if (song == null) return null;

      final encryptedUrl = song['encrypted_media_url'] as String?;
      final url = _decryptUrl(encryptedUrl);
      if (url == null) return null;

      final has320 = (song['320kbps'] as String?) == 'true';
      return has320 ? _upgradeTo320(url) : url;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _client.close();
}
