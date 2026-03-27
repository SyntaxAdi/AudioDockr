import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/backend_api_client.dart';

final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  return BackendApiClient();
});

final searchProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<List<SearchResult>>>((ref) {
  final apiClient = ref.read(backendApiClientProvider);
  return SearchNotifier(apiClient);
});

class SearchFailure implements Exception {
  const SearchFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class SearchResult {
  const SearchResult({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.duration,
    required this.thumbnailUrl,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final Duration duration;
  final String thumbnailUrl;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final thumbnails = json['thumbnails'];
    String thumbnailUrl = '';

    if (thumbnails is List && thumbnails.isNotEmpty) {
      final last = thumbnails.last;
      if (last is Map<String, dynamic>) {
        thumbnailUrl = (last['url'] as String?) ?? '';
      } else if (last is Map) {
        thumbnailUrl = (last['url']?.toString()) ?? '';
      }
    }

    final durationSeconds =
        int.tryParse(json['duration']?.toString() ?? '') ?? 0;

    return SearchResult(
      videoId: (json['id']?.toString()) ?? '',
      videoUrl: (json['url']?.toString()) ?? '',
      title: (json['title']?.toString()) ?? 'Unknown title',
      artist: (json['uploader']?.toString()) ?? 'Unknown uploader',
      duration: Duration(seconds: durationSeconds),
      thumbnailUrl: thumbnailUrl,
    );
  }
}

class SearchNotifier extends StateNotifier<AsyncValue<List<SearchResult>>> {
  SearchNotifier(this._apiClient) : super(const AsyncValue.data([]));

  final BackendApiClient _apiClient;

  String _latestQuery = '';

  Future<void> search(String query) async {
    final trimmedQuery = query.trim();
    _latestQuery = trimmedQuery;

    if (trimmedQuery.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final response = await _apiClient.search(trimmedQuery);

      if (_latestQuery != trimmedQuery) {
        return;
      }

      final results = <SearchResult>[];

      for (final item in response.items) {
        final result = SearchResult.fromJson(item);
        if (result.videoId.isNotEmpty) {
          results.add(result);
        }
      }

      state = AsyncValue.data(results);
    } catch (error, stackTrace) {
      if (_latestQuery != trimmedQuery) {
        return;
      }
      final mappedError = _mapSearchError(error);
      if (mappedError.code == 'no_results') {
        state = const AsyncValue.data([]);
        return;
      }
      state = AsyncValue.error(mappedError, stackTrace);
    }
  }

  void clear() {
    _latestQuery = '';
    state = const AsyncValue.data([]);
  }

  SearchFailure _mapSearchError(Object error) {
    if (error is SearchFailure) {
      return error;
    }

    if (error is BackendApiException) {
      switch (error.code) {
        case 'backend_not_configured':
          return const SearchFailure(
            'backend_not_configured',
            'Backend URL is not configured. Start the yt-dlp server and launch the app with AUDIODOCKR_API_BASE_URL.',
          );
        case 'temporary_unavailable':
          return const SearchFailure(
            'temporary_unavailable',
            'The yt-dlp backend is temporarily unavailable. Please try again in a moment.',
          );
        case 'rate_limited':
          return const SearchFailure(
            'rate_limited',
            'The backend is being rate limited by YouTube right now. Please wait a bit and retry.',
          );
        case 'integrity_check_required':
          return const SearchFailure(
            'integrity_check_required',
            'The backend needs extra YouTube verification right now. Please try again later.',
          );
        case 'unsupported_response':
          return const SearchFailure(
            'unsupported_response',
            'yt-dlp could not parse YouTube\'s latest response format.',
          );
        case 'no_results':
          return const SearchFailure(
            'no_results',
            'No matching songs were found on YouTube.',
          );
        default:
          return SearchFailure(
            error.code,
            error.message ?? 'Search failed. Please try again.',
          );
      }
    }

    return const SearchFailure(
      'search_failed',
      'Search failed. Please try again.',
    );
  }
}
