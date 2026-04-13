import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/youtube_service.dart';
import '../library/library_provider.dart';
import '../playback/playback_url_resolver.dart';
import '../settings/app_preferences.dart';
import 'download_models.dart';
import 'download_service.dart';

const _completedDownloadsKey = 'completed_downloads';

final downloadPathProvider = FutureProvider<String>((ref) async {
  return AppPreferences.loadDownloadPath();
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(
    resolver: PlaybackUrlResolver(
      youtubeService: ref.read(youtubeServiceProvider),
      libraryNotifier: ref.read(libraryProvider.notifier),
    ),
  );
});

final downloadNotifierProvider =
    StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  return DownloadNotifier(
    downloadService: ref.read(downloadServiceProvider),
  );
});

class DownloadNotifier extends StateNotifier<DownloadState> {
  DownloadNotifier({
    required DownloadService downloadService,
  })  : _downloadService = downloadService,
        super(const DownloadState()) {
    unawaited(_loadCompletedDownloads());
  }

  final DownloadService _downloadService;
  final Map<String, DownloadCancellationHandle> _cancellations = {};

  Future<void> startDownload({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
  }) async {
    final existing = state.recordForTrack(videoId);
    if (existing?.isDownloading == true || existing?.isCompleted == true) {
      return;
    }

    final startedAt = DateTime.now().millisecondsSinceEpoch;
    final cancellationHandle = DownloadCancellationHandle();
    _cancellations[videoId] = cancellationHandle;

    state = state.copyWith(
      activeDownloads: {
        ...state.activeDownloads,
        videoId: DownloadRecord(
          videoId: videoId,
          videoUrl: videoUrl,
          title: title,
          artist: artist,
          thumbnailUrl: thumbnailUrl,
          status: DownloadStatus.downloading,
          progress: 0,
          startedAt: startedAt,
        ),
      },
    );

    try {
      await DownloadService.ensureDownloadPermissions();
      final downloadPath = await AppPreferences.loadDownloadPath();
      final result = await _downloadService.downloadTrack(
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        downloadDirectoryPath: downloadPath,
        cancellationHandle: cancellationHandle,
        onProgress: (progress) {
          final current = state.activeDownloads[videoId];
          if (current == null) {
            return;
          }
          state = state.copyWith(
            activeDownloads: {
              ...state.activeDownloads,
              videoId: current.copyWith(
                progress: progress,
              ),
            },
          );
        },
      );

      final completedAt = DateTime.now().millisecondsSinceEpoch;
      final activeDownloads = Map<String, DownloadRecord>.from(state.activeDownloads)
        ..remove(videoId);
      final completedRecord = DownloadRecord(
        videoId: videoId,
        videoUrl: result.videoUrl,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        status: DownloadStatus.completed,
        progress: 1,
        localPath: result.localPath,
        startedAt: startedAt,
        completedAt: completedAt,
      );

      final completedDownloads = [
        completedRecord,
        ...state.completedDownloads.where((record) => record.videoId != videoId),
      ];

      state = state.copyWith(
        activeDownloads: activeDownloads,
        completedDownloads: completedDownloads,
        isLoaded: true,
      );
      await _persistCompletedDownloads(completedDownloads);
    } on DownloadFailure catch (error) {
      final activeDownloads = Map<String, DownloadRecord>.from(state.activeDownloads)
        ..remove(videoId);
      state = state.copyWith(activeDownloads: activeDownloads);
      if (error.code != 'download_cancelled') {
        rethrow;
      }
    } finally {
      _cancellations.remove(videoId);
    }
  }

  Future<void> cancelDownload(String videoId) async {
    _cancellations.remove(videoId)?.cancel();
    final activeDownloads = Map<String, DownloadRecord>.from(state.activeDownloads)
      ..remove(videoId);
    state = state.copyWith(activeDownloads: activeDownloads);
  }

  Future<void> deleteDownload(String videoId) async {
    final record = state.completedDownloads
        .where((r) => r.videoId == videoId)
        .firstOrNull;
    if (record == null) return;

    final path = record.localPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    final updated = state.completedDownloads
        .where((r) => r.videoId != videoId)
        .toList(growable: false);
    state = state.copyWith(completedDownloads: updated);
    await _persistCompletedDownloads(updated);
  }

  Future<void> _loadCompletedDownloads() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_completedDownloadsKey);
    if (rawValue == null || rawValue.trim().isEmpty) {
      state = state.copyWith(isLoaded: true);
      return;
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! List) {
        state = state.copyWith(isLoaded: true);
        return;
      }

      final completedDownloads = <DownloadRecord>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        final record = DownloadRecord.fromJson(
          Map<String, dynamic>.from(item),
        );
        final localPath = record.localPath;
        if (localPath == null || localPath.isEmpty) {
          continue;
        }
        if (!await File(localPath).exists()) {
          continue;
        }
        completedDownloads.add(record);
      }

      state = state.copyWith(
        completedDownloads: completedDownloads,
        isLoaded: true,
      );
      await _persistCompletedDownloads(completedDownloads);
    } catch (_) {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> _persistCompletedDownloads(
    List<DownloadRecord> completedDownloads,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      completedDownloads.map((record) => record.toJson()).toList(growable: false),
    );
    await preferences.setString(_completedDownloadsKey, encoded);
  }
}
