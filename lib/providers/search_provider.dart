import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database_helper.dart';
import '../api/youtube_service.dart';

final searchProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<List<SearchResult>>>((ref) {
  final youtubeService = ref.read(youtubeServiceProvider);
  final databaseHelper = DatabaseHelper.instance;
  return SearchNotifier(youtubeService, databaseHelper);
});

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier(DatabaseHelper.instance);
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
  SearchNotifier(this._youtubeService, this._databaseHelper)
      : super(const AsyncValue.data([]));

  final YoutubeService _youtubeService;
  final DatabaseHelper _databaseHelper;

  String _latestQuery = '';

  Future<void> search(String query, {bool saveToHistory = false}) async {
    final trimmedQuery = query.trim();
    _latestQuery = trimmedQuery;

    if (trimmedQuery.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      if (saveToHistory) {
        await _databaseHelper.saveSearchQuery(trimmedQuery);
      }
      final items = await _youtubeService.search(trimmedQuery);

      if (_latestQuery != trimmedQuery) {
        return;
      }

      state = AsyncValue.data(
        items
            .map(
              (item) => SearchResult(
                videoId: item.id,
                videoUrl: item.url,
                title: item.title,
                artist: item.uploader,
                duration: item.duration,
                thumbnailUrl: item.thumbnailUrl,
              ),
            )
            .toList(),
      );
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

    if (error is YoutubeServiceException) {
      switch (error.code) {
        case 'temporary_unavailable':
          return const SearchFailure(
            'temporary_unavailable',
            'YouTube is temporarily unavailable. Please try again in a moment.',
          );
        case 'rate_limited':
          return const SearchFailure(
            'rate_limited',
            'YouTube is rate limiting requests right now. Please wait a bit and retry.',
          );
        case 'unsupported_response':
          return const SearchFailure(
            'unsupported_response',
            'YouTube returned a response this app could not parse.',
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

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier(this._databaseHelper) : super(const []) {
    load();
  }

  final DatabaseHelper _databaseHelper;

  Future<void> load() async {
    state = await _databaseHelper.fetchSearchHistory();
  }
}
