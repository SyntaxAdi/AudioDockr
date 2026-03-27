import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class BackendApiException implements Exception {
  const BackendApiException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class BackendSearchResponse {
  const BackendSearchResponse(this.items);

  final List<Map<String, dynamic>> items;
}

class BackendApiClient {
  BackendApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<BackendSearchResponse> search(String query) async {
    final response = await _post(
      '/search',
      {'query': query},
    );

    final items = response['items'];
    if (items is! List) {
      throw const BackendApiException(
        'unsupported_response',
        'The backend returned an invalid search response.',
      );
    }

    return BackendSearchResponse(
      items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }

  Future<String> extractAudioUrl({
    required String videoId,
    required String videoUrl,
  }) async {
    final response = await _post(
      '/extract',
      {
        'video_id': videoId,
        'video_url': videoUrl,
      },
    );

    final audioUrl = response['audio_url']?.toString() ?? '';
    if (audioUrl.isEmpty) {
      throw const BackendApiException(
        'extract_failed',
        'The backend did not return a playable audio URL.',
      );
    }
    return audioUrl;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    if (!ApiConfig.isConfigured) {
      throw const BackendApiException(
        'backend_not_configured',
        'Backend URL is not configured. Launch Flutter with --dart-define=AUDIODOCKR_API_BASE_URL=http://YOUR_SERVER:8000',
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    late final http.Response response;

    try {
      response = await _httpClient.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (_) {
      throw const BackendApiException(
        'temporary_unavailable',
        'Cannot reach the backend right now. Check that the server is running and reachable from this device.',
      );
    }

    Map<String, dynamic> body = const {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      } else if (decoded is Map) {
        body = Map<String, dynamic>.from(decoded);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw BackendApiException(
      body['code']?.toString() ?? 'request_failed',
      body['message']?.toString() ?? 'Backend request failed.',
    );
  }
}
