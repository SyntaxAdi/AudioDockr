import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/youtube_service.dart';
import '../library/library_provider.dart';
import '../playback/playback_url_resolver.dart';
import '../settings/app_preferences.dart';
import '../services/notification_service.dart';
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

final downloadedLibraryTracksProvider =
    FutureProvider<List<LibraryTrack>>((ref) async {
  final downloadState = ref.watch(downloadNotifierProvider);
  final downloadPath = await AppPreferences.loadDownloadPath();

  final tracks = <LibraryTrack>[];
  final seenPaths = <String>{};

  for (final record in downloadState.completedDownloads) {
    final localPath = record.localPath;
    if (localPath == null || localPath.isEmpty) {
      continue;
    }
    final normalizedPath = path.normalize(localPath);
    if (!await File(normalizedPath).exists() || !seenPaths.add(normalizedPath)) {
      continue;
    }
    tracks.add(
      LibraryTrack(
        videoId: record.videoId,
        videoUrl: record.videoUrl,
        title: record.title,
        artist: record.artist,
        durationSeconds: 0,
        thumbnailUrl: record.thumbnailUrl,
        reaction: 'neutral',
        localFilePath: normalizedPath,
      ),
    );
  }

  final directory = Directory(downloadPath);
  if (await directory.exists()) {
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final extension = path.extension(entity.path).toLowerCase();
      if (!_supportedAudioExtensions.contains(extension)) {
        continue;
      }
      final normalizedPath = path.normalize(entity.path);
      if (!seenPaths.add(normalizedPath)) {
        continue;
      }
      final metadata = await DownloadService.readLocalMetadata(normalizedPath);
      final parsed = _parseTrackNameFromPath(normalizedPath);
      tracks.add(
        LibraryTrack(
          videoId: 'local_file_$normalizedPath',
          videoUrl: '',
          title: metadata.title?.isNotEmpty == true ? metadata.title! : parsed.title,
          artist:
              metadata.artist?.isNotEmpty == true ? metadata.artist! : parsed.artist,
          durationSeconds: 0,
          thumbnailUrl: '',
          reaction: 'neutral',
          localFilePath: normalizedPath,
        ),
      );
    }
  }

  tracks.sort((a, b) {
    final aName = (a.localFilePath ?? '').toLowerCase();
    final bName = (b.localFilePath ?? '').toLowerCase();
    return aName.compareTo(bName);
  });

  return tracks;
});

const Set<String> _supportedAudioExtensions = {
  '.mp3',
  '.m4a',
  '.aac',
  '.wav',
  '.flac',
  '.ogg',
  '.opus',
};

({String title, String artist}) _parseTrackNameFromPath(String filePath) {
  final fileName = path.basenameWithoutExtension(filePath).trim();
  final separatorIndex = fileName.indexOf(' - ');
  if (separatorIndex > 0 && separatorIndex < fileName.length - 3) {
    return (
      artist: fileName.substring(0, separatorIndex).trim(),
      title: fileName.substring(separatorIndex + 3).trim(),
    );
  }
  return (
    artist: 'Local file',
    title: fileName.isEmpty ? 'Unknown track' : fileName,
  );
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  DownloadNotifier({
    required DownloadService downloadService,
  })  : _downloadService = downloadService,
        super(const DownloadState()) {
    unawaited(_loadCompletedDownloads());
  }

  final DownloadService _downloadService;
  final Map<String, DownloadCancellationHandle> _cancellations = {};
  
  bool _isProcessingQueue = false;

  Future<void> startDownload({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    String? playlistId,
    String? playlistTitle,
    String? playlistThumbnailUrl,
  }) async {
    final existing = state.recordForTrack(videoId);
    if (existing?.isDownloading == true || existing?.isCompleted == true || existing?.isQueued == true) {
      return;
    }

    final startedAt = DateTime.now().millisecondsSinceEpoch;

    state = state.copyWith(
      activeDownloads: {
        ...state.activeDownloads,
        videoId: DownloadRecord(
          videoId: videoId,
          videoUrl: videoUrl,
          title: title,
          artist: artist,
          thumbnailUrl: thumbnailUrl,
          status: DownloadStatus.queued,
          progress: 0,
          startedAt: startedAt,
          playlistId: playlistId,
          playlistTitle: playlistTitle,
          playlistThumbnailUrl: playlistThumbnailUrl,
        ),
      },
    );

    unawaited(_processQueue());
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    try {
      while (true) {
        final nextId = _getNextQueuedTrackId();
        if (nextId == null) break;

        await _performDownload(nextId);
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  String? _getNextQueuedTrackId() {
    final queued = state.activeDownloads.values
        .where((r) => r.status == DownloadStatus.queued)
        .toList();
    
    if (queued.isEmpty) return null;

    // Sort by startedAt to process in order
    queued.sort((a, b) => (a.startedAt ?? 0).compareTo(b.startedAt ?? 0));
    return queued.first.videoId;
  }

  Future<void> _performDownload(String videoId) async {
    final record = state.activeDownloads[videoId];
    if (record == null) return;

    final cancellationHandle = DownloadCancellationHandle();
    _cancellations[videoId] = cancellationHandle;

    state = state.copyWith(
      activeDownloads: {
        ...state.activeDownloads,
        videoId: record.copyWith(status: DownloadStatus.downloading),
      },
    );

    final playlistId = record.playlistId;

    try {
      await DownloadService.ensureDownloadPermissions();
      
      // Trigger initial notification immediately before actual download starts
      if (playlistId != null) {
        final playlistRecord = state.activePlaylistDownloads[playlistId];
        if (playlistRecord != null) {
          NotificationService.instance.showPlaylistProgress(
            playlistName: playlistRecord.title,
            totalTracks: playlistRecord.trackCount,
            completedTracks: playlistRecord.completedCount,
            averageProgress: (playlistRecord.averageProgress * 100).toInt(),
          );
        }
      } else {
        NotificationService.instance.showDownloadProgress(
          title: record.title,
          progress: 0,
        );
      }

      final downloadPath = await AppPreferences.loadDownloadPath();
      final result = await _downloadService.downloadTrack(
        videoId: videoId,
        videoUrl: record.videoUrl,
        title: record.title,
        artist: record.artist,
        thumbnailUrl: record.thumbnailUrl,
        downloadDirectoryPath: downloadPath,
        cancellationHandle: cancellationHandle,
        onProgress: (progress) {
          final current = state.activeDownloads[videoId];
          if (current == null) return;

          final updatedRecord = current.copyWith(progress: progress);
          final updatedActiveDownloads = {
            ...state.activeDownloads,
            videoId: updatedRecord,
          };
          
          Map<String, PlaylistDownloadRecord>? updatedPlaylistDownloads;
          if (playlistId != null) {
            final playlistRecord = state.activePlaylistDownloads[playlistId];
            if (playlistRecord != null) {
              final updatedPlaylist = _calculatePlaylistProgress(playlistId, updatedActiveDownloads);
              updatedPlaylistDownloads = {
                ...state.activePlaylistDownloads,
                playlistId: updatedPlaylist,
              };

              // Notification for playlist
              NotificationService.instance.showPlaylistProgress(
                playlistName: playlistRecord.title,
                totalTracks: playlistRecord.trackCount,
                completedTracks: updatedPlaylist.completedCount,
                averageProgress: (updatedPlaylist.averageProgress * 100).toInt(),
              );
            }
          } else {
            // Notification for single track
            NotificationService.instance.showDownloadProgress(
              title: current.title,
              progress: (progress * 100).toInt(),
            );
          }

          state = state.copyWith(
            activeDownloads: updatedActiveDownloads,
            activePlaylistDownloads: updatedPlaylistDownloads,
          );
        },
      );

      final completedAt = DateTime.now().millisecondsSinceEpoch;
      final activeDownloads = Map<String, DownloadRecord>.from(state.activeDownloads)
        ..remove(videoId);

      if (playlistId != null) {
        final playlistRecord = state.activePlaylistDownloads[playlistId];
        if (playlistRecord != null) {
          final updatedPlaylist = _calculatePlaylistProgress(
            playlistId,
            activeDownloads,
          );
          if (updatedPlaylist.completedCount != updatedPlaylist.trackCount) {
            NotificationService.instance.showPlaylistProgress(
              playlistName: playlistRecord.title,
              totalTracks: playlistRecord.trackCount,
              completedTracks: updatedPlaylist.completedCount,
              averageProgress: (updatedPlaylist.averageProgress * 100).toInt(),
            );
          }
        }
      }
      final completedRecord = DownloadRecord(
        videoId: videoId,
        videoUrl: result.videoUrl,
        title: record.title,
        artist: record.artist,
        thumbnailUrl: record.thumbnailUrl,
        status: DownloadStatus.completed,
        progress: 1,
        localPath: result.localPath,
        startedAt: record.startedAt,
        completedAt: completedAt,
        playlistId: record.playlistId,
        playlistTitle: record.playlistTitle,
      );

      final completedDownloads = [
        completedRecord,
        ...state.completedDownloads.where((r) => r.videoId != videoId),
      ];

      Map<String, PlaylistDownloadRecord>? updatedPlaylistDownloads;
      if (playlistId != null) {
        final playlistRecord = state.activePlaylistDownloads[playlistId];
        if (playlistRecord != null) {
          final updatedPlaylist = _calculatePlaylistProgress(
            playlistId,
            activeDownloads,
          );
          if (updatedPlaylist.completedCount == updatedPlaylist.trackCount) {
            updatedPlaylistDownloads = Map.from(state.activePlaylistDownloads)
              ..remove(playlistId);
          } else {
            updatedPlaylistDownloads = {
              ...state.activePlaylistDownloads,
              playlistId: updatedPlaylist,
            };
          }
        }
      }

      state = state.copyWith(
        activeDownloads: activeDownloads,
        activePlaylistDownloads: updatedPlaylistDownloads,
        completedDownloads: completedDownloads,
        isLoaded: true,
      );
      await _persistCompletedDownloads(completedDownloads);
      await _showCompletionMessageIfDone();
    } on DownloadFailure catch (error) {
      // Cancel notification if it failed or was manually cancelled
      NotificationService.instance.cancelDownloadNotification();

      if (error.code == 'download_cancelled') {
        return; // The cancelling action already updated the state, just terminate
      }

      final activeDownloads =
          Map<String, DownloadRecord>.from(state.activeDownloads)
            ..remove(videoId);

      Map<String, PlaylistDownloadRecord>? updatedPlaylistDownloads;
      if (playlistId != null) {
        final playlistRecord = state.activePlaylistDownloads[playlistId];
        if (playlistRecord != null) {
           final updatedPlaylist = _calculatePlaylistProgress(playlistId, activeDownloads);
           updatedPlaylistDownloads = {
              ...state.activePlaylistDownloads,
              playlistId: updatedPlaylist.copyWith(
                trackCount: playlistRecord.trackCount - 1,
              ),
            };
            if (updatedPlaylistDownloads[playlistId]!.trackCount <= updatedPlaylistDownloads[playlistId]!.completedCount) {
               updatedPlaylistDownloads.remove(playlistId);
            }
        }
      }

      state = state.copyWith(
        activeDownloads: activeDownloads,
        activePlaylistDownloads: updatedPlaylistDownloads,
      );
    } finally {
      _cancellations.remove(videoId);
    }
  }

  Future<void> startPlaylistDownload({
    required String playlistId,
    required String title,
    required String thumbnailUrl,
    required List<({String videoId, String videoUrl, String title, String artist, String thumbnailUrl})> tracks,
  }) async {
    if (state.activePlaylistDownloads.containsKey(playlistId)) {
      return;
    }

    state = state.copyWith(
      activePlaylistDownloads: {
        ...state.activePlaylistDownloads,
        playlistId: PlaylistDownloadRecord(
          playlistId: playlistId,
          title: title,
          thumbnailUrl: thumbnailUrl,
          trackCount: tracks.length,
          completedCount: 0,
          averageProgress: 0,
          startedAt: DateTime.now().millisecondsSinceEpoch,
          trackIds: tracks.map((t) => t.videoId).toList(),
        ),
      },
    );

    for (final track in tracks) {
      // These will be added as 'queued' and _processQueue will be called
      unawaited(startDownload(
        videoId: track.videoId,
        videoUrl: track.videoUrl,
        title: track.title,
        artist: track.artist,
        thumbnailUrl: track.thumbnailUrl,
        playlistId: playlistId,
        playlistTitle: title,
        playlistThumbnailUrl: thumbnailUrl,
      ));
    }
  }

  PlaylistDownloadRecord _calculatePlaylistProgress(String playlistId, Map<String, DownloadRecord> activeDownloads) {
    final playlistRecord = state.activePlaylistDownloads[playlistId]!;
    
    final playlistTracksInActive = activeDownloads.values.where((r) => r.playlistId == playlistId).toList();
    final activeCount = playlistTracksInActive.length;
    final completedCount = playlistRecord.trackCount - activeCount;
    
    double totalProgress = completedCount.toDouble();
    for (final r in playlistTracksInActive) {
      totalProgress += r.progress;
    }
    
    final averageProgress = totalProgress / playlistRecord.trackCount;
    
    return playlistRecord.copyWith(
      completedCount: completedCount,
      averageProgress: averageProgress,
    );
  }

  Future<void> cancelDownload(String videoId) async {
    final record = state.activeDownloads[videoId];
    _cancellations.remove(videoId)?.cancel();
    final activeDownloads = Map<String, DownloadRecord>.from(state.activeDownloads)
      ..remove(videoId);
    
    Map<String, PlaylistDownloadRecord>? updatedPlaylistDownloads;
    if (record?.playlistId != null) {
      final playlistId = record!.playlistId!;
      final playlistRecord = state.activePlaylistDownloads[playlistId];
      if (playlistRecord != null) {
        final updatedPlaylist = _calculatePlaylistProgress(playlistId, activeDownloads);
        updatedPlaylistDownloads = {
          ...state.activePlaylistDownloads,
          playlistId: updatedPlaylist.copyWith(
            trackCount: playlistRecord.trackCount - 1,
            trackIds: List.from(playlistRecord.trackIds)..remove(videoId),
          ),
        };
        if (updatedPlaylistDownloads[playlistId]!.trackCount <= updatedPlaylistDownloads[playlistId]!.completedCount) {
          updatedPlaylistDownloads.remove(playlistId);
        }
      }
    }

    state = state.copyWith(
      activeDownloads: activeDownloads,
      activePlaylistDownloads: updatedPlaylistDownloads,
    );
  }

  Future<void> cancelPlaylistDownload(String playlistId) async {
    final playlistRecord = state.activePlaylistDownloads[playlistId];
    if (playlistRecord == null) return;

    for (final videoId in playlistRecord.trackIds) {
      _cancellations.remove(videoId)?.cancel();
    }

    final activeDownloads = Map<String, DownloadRecord>.from(state.activeDownloads)
      ..removeWhere((key, value) => value.playlistId == playlistId);
    
    final activePlaylistDownloads = Map<String, PlaylistDownloadRecord>.from(state.activePlaylistDownloads)
      ..remove(playlistId);

    state = state.copyWith(
      activeDownloads: activeDownloads,
      activePlaylistDownloads: activePlaylistDownloads,
    );
  }

  Future<void> cancelAllDownloads() async {
    for (final cancellation in _cancellations.values) {
      cancellation.cancel();
    }
    _cancellations.clear();
    state = state.copyWith(
      activeDownloads: {},
      activePlaylistDownloads: {},
    );
  }

  Future<void> togglePauseDownload(String videoId) async {
    final record = state.activeDownloads[videoId];
    if (record == null) return;

    if (record.isPaused) {
      state = state.copyWith(
        activeDownloads: {
          ...state.activeDownloads,
          videoId: record.copyWith(status: DownloadStatus.queued),
        },
      );
      unawaited(_processQueue());
    } else {
      _cancellations.remove(videoId)?.cancel();
      // Keep it in activeDownloads but paused
      state = state.copyWith(
        activeDownloads: {
          ...state.activeDownloads,
          videoId: record.copyWith(status: DownloadStatus.paused),
        },
      );
    }
  }

  Future<void> togglePausePlaylistDownload(String playlistId) async {
    final playlistRecord = state.activePlaylistDownloads[playlistId];
    if (playlistRecord == null) return;

    final isNowPaused = !playlistRecord.isPaused;
    
    final updatedActiveDownloads = Map<String, DownloadRecord>.from(state.activeDownloads);
    for (final videoId in playlistRecord.trackIds) {
      final track = updatedActiveDownloads[videoId];
      if (track != null) {
        if (isNowPaused) {
          _cancellations.remove(videoId)?.cancel();
          updatedActiveDownloads[videoId] = track.copyWith(status: DownloadStatus.paused);
        } else {
          updatedActiveDownloads[videoId] = track.copyWith(status: DownloadStatus.queued);
        }
      }
    }

    state = state.copyWith(
      activeDownloads: updatedActiveDownloads,
      activePlaylistDownloads: {
        ...state.activePlaylistDownloads,
        playlistId: playlistRecord.copyWith(isPaused: isNowPaused),
      },
    );

    if (!isNowPaused) {
      unawaited(_processQueue());
    }
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

  Future<void> deleteAllDownloads() async {
    for (final record in state.completedDownloads) {
      final path = record.localPath;
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
    }

    state = state.copyWith(completedDownloads: []);
    await _persistCompletedDownloads([]);
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
      completedDownloads
          .map((record) => record.toJson())
          .toList(growable: false),
    );
    await preferences.setString(_completedDownloadsKey, encoded);
  }

  Future<void> _showCompletionMessageIfDone() async {
    if (state.activeDownloads.isNotEmpty) return;
    if (state.activePlaylistDownloads.isNotEmpty) return;

    await NotificationService.instance.showAllDownloadsCompletedAlert();
  }
}
