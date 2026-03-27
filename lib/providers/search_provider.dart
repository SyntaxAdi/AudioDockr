import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchProvider =
    StateNotifierProvider<SearchNotifier, AsyncValue<List<SearchResult>>>((ref) {
  return SearchNotifier();
});

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
  SearchNotifier() : super(const AsyncValue.data([]));

  static const MethodChannel _channel = MethodChannel('audiodockr/search');

  String _latestQuery = '';

  Future<void> search(String query) async {
    final trimmedQuery = query.trim();
    _latestQuery = trimmedQuery;

    if (trimmedQuery.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      state = AsyncValue.error(
        UnsupportedError(
          'YouTube search is only wired for Android right now. Run the app on an Android device or emulator.',
        ),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final lines = await _channel.invokeListMethod<String>(
        'search',
        {'query': trimmedQuery},
      );

      if (_latestQuery != trimmedQuery) {
        return;
      }

      final results = <SearchResult>[];

      for (final line in lines ?? <String>[]) {
        if (line.trim().isEmpty) {
          continue;
        }

        if (line.startsWith('ERROR:')) {
          throw PlatformException(
            code: 'SEARCH_FAILED',
            message: line,
          );
        }

        try {
          final decoded = jsonDecode(line);
          if (decoded is Map<String, dynamic>) {
            final result = SearchResult.fromJson(decoded);
            if (result.videoId.isNotEmpty) {
              results.add(result);
            }
          } else if (decoded is Map) {
            final result =
                SearchResult.fromJson(Map<String, dynamic>.from(decoded));
            if (result.videoId.isNotEmpty) {
              results.add(result);
            }
          }
        } on FormatException {
          // Ignore non-JSON noise from the native process and keep parsing.
        }
      }

      state = AsyncValue.data(results);
    } catch (error, stackTrace) {
      if (_latestQuery != trimmedQuery) {
        return;
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clear() {
    _latestQuery = '';
    state = const AsyncValue.data([]);
  }
}
