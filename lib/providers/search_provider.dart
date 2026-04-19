import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database_helper.dart';
import '../api/youtube_service.dart';
import '../settings/app_preferences.dart';

final searchProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<List<SearchResult>>>(
        (ref) {
  final youtubeService = ref.read(youtubeServiceProvider);
  final databaseHelper = DatabaseHelper.instance;
  return SearchNotifier(youtubeService, databaseHelper);
});

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier(DatabaseHelper.instance);
});

final searchPreferencesProvider =
    StateNotifierProvider<SearchPreferencesNotifier, SearchPreferences>((ref) {
  return SearchPreferencesNotifier();
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
    required this.lowThumbnailUrl,
    required this.mediumThumbnailUrl,
    required this.highThumbnailUrl,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final Duration duration;
  final String lowThumbnailUrl;
  final String mediumThumbnailUrl;
  final String highThumbnailUrl;

  String get thumbnailUrl => highThumbnailUrl;

  String thumbnailUrlFor(SearchThumbnailQuality quality) {
    switch (quality) {
      case SearchThumbnailQuality.low:
        return lowThumbnailUrl;
      case SearchThumbnailQuality.medium:
        return mediumThumbnailUrl;
      case SearchThumbnailQuality.high:
        return highThumbnailUrl;
    }
  }

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final thumbnails = json['thumbnails'];
    final thumbnailUrls = <String>[];

    if (thumbnails is List && thumbnails.isNotEmpty) {
      for (final thumbnail in thumbnails) {
        if (thumbnail is Map<String, dynamic>) {
          thumbnailUrls.add((thumbnail['url'] as String?) ?? '');
        } else if (thumbnail is Map) {
          thumbnailUrls.add((thumbnail['url']?.toString()) ?? '');
        }
      }
    }

    final durationSeconds =
        int.tryParse(json['duration']?.toString() ?? '') ?? 0;
    final videoId = (json['id']?.toString()) ?? '';
    final fallbackThumbnailUrl = thumbnailUrls.isNotEmpty
        ? thumbnailUrls.last
        : _youtubeThumbnailUrl(videoId, 'hqdefault');

    return SearchResult(
      videoId: videoId,
      videoUrl: (json['url']?.toString()) ?? '',
      title: (json['title']?.toString()) ?? 'Unknown title',
      artist: (json['uploader']?.toString()) ?? 'Unknown uploader',
      duration: Duration(seconds: durationSeconds),
      lowThumbnailUrl: thumbnailUrls.isNotEmpty
          ? thumbnailUrls.first
          : _youtubeThumbnailUrl(videoId, 'default'),
      mediumThumbnailUrl: thumbnailUrls.length > 1
          ? thumbnailUrls[1]
          : _youtubeThumbnailUrl(videoId, 'mqdefault'),
      highThumbnailUrl: fallbackThumbnailUrl,
    );
  }
}

String _youtubeThumbnailUrl(String videoId, String fileName) {
  if (videoId.isEmpty) {
    return '';
  }
  return 'https://img.youtube.com/vi/$videoId/$fileName.jpg';
}

class SearchPreferences {
  const SearchPreferences({
    required this.resultLimit,
    required this.thumbnailQuality,
  });

  factory SearchPreferences.defaults() {
    return const SearchPreferences(
      resultLimit: AppPreferences.defaultSearchResultLimit,
      thumbnailQuality: AppPreferences.defaultSearchThumbnailQuality,
    );
  }

  final int resultLimit;
  final SearchThumbnailQuality thumbnailQuality;

  SearchPreferences copyWith({
    int? resultLimit,
    SearchThumbnailQuality? thumbnailQuality,
  }) {
    return SearchPreferences(
      resultLimit: resultLimit ?? this.resultLimit,
      thumbnailQuality: thumbnailQuality ?? this.thumbnailQuality,
    );
  }
}

class SearchPreferencesNotifier extends StateNotifier<SearchPreferences> {
  SearchPreferencesNotifier() : super(SearchPreferences.defaults()) {
    load();
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    state = SearchPreferences(
      resultLimit: AppPreferences.readSearchResultLimit(preferences),
      thumbnailQuality: AppPreferences.readSearchThumbnailQuality(preferences),
    );
  }

  Future<void> setResultLimit(int value) async {
    final limit =
        value.clamp(1, AppPreferences.defaultSearchResultLimit).toInt();
    state = state.copyWith(resultLimit: limit);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(AppPreferences.searchResultLimitKey, limit);
  }

  Future<void> setThumbnailQuality(SearchThumbnailQuality value) async {
    state = state.copyWith(thumbnailQuality: value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
        AppPreferences.searchThumbnailQualityKey, value.name);
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
      final futures = <Future<Object?>>[
        _youtubeService.search(trimmedQuery),
        if (saveToHistory) _databaseHelper.saveSearchQuery(trimmedQuery),
      ];
      final results = await Future.wait(futures);
      final items = results.first as List<YoutubeSearchItem>;

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
                lowThumbnailUrl: item.lowThumbnailUrl,
                mediumThumbnailUrl: item.mediumThumbnailUrl,
                highThumbnailUrl: item.highThumbnailUrl,
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
            error.message,
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

  Future<void> addQuery(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return;
    }

    state = [
      trimmedQuery,
      ...state.where((item) => item != trimmedQuery),
    ].take(12).toList();

    await _databaseHelper.saveSearchQuery(trimmedQuery);
  }

  Future<void> load() async {
    state = await _databaseHelper.fetchSearchHistory();
  }
}
