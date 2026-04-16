enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
}

class DownloadRecord {
  const DownloadRecord({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.status,
    this.progress = 0,
    this.localPath,
    this.startedAt,
    this.completedAt,
    this.playlistId,
    this.playlistTitle,
    this.playlistThumbnailUrl,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final DownloadStatus status;
  final double progress;
  final String? localPath;
  final int? startedAt;
  final int? completedAt;
  final String? playlistId;
  final String? playlistTitle;
  final String? playlistThumbnailUrl;

  bool get isQueued => status == DownloadStatus.queued;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isCompleted => status == DownloadStatus.completed;

  DownloadRecord copyWith({
    String? videoId,
    String? videoUrl,
    String? title,
    String? artist,
    String? thumbnailUrl,
    DownloadStatus? status,
    double? progress,
    Object? localPath = _unsetField,
    int? startedAt,
    int? completedAt,
    Object? playlistId = _unsetField,
    Object? playlistTitle = _unsetField,
    Object? playlistThumbnailUrl = _unsetField,
  }) {
    return DownloadRecord(
      videoId: videoId ?? this.videoId,
      videoUrl: videoUrl ?? this.videoUrl,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: identical(localPath, _unsetField)
          ? this.localPath
          : localPath as String?,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      playlistId: identical(playlistId, _unsetField)
          ? this.playlistId
          : playlistId as String?,
      playlistTitle: identical(playlistTitle, _unsetField)
          ? this.playlistTitle
          : playlistTitle as String?,
      playlistThumbnailUrl: identical(playlistThumbnailUrl, _unsetField)
          ? this.playlistThumbnailUrl
          : playlistThumbnailUrl as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'videoUrl': videoUrl,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'localPath': localPath,
      'completedAt': completedAt,
      'playlistId': playlistId,
      'playlistTitle': playlistTitle,
      'playlistThumbnailUrl': playlistThumbnailUrl,
    };
  }

  factory DownloadRecord.fromJson(Map<String, dynamic> json) {
    return DownloadRecord(
      videoId: (json['videoId'] as String?) ?? '',
      videoUrl: (json['videoUrl'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Unknown track',
      artist: (json['artist'] as String?) ?? 'Unknown artist',
      thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
      status: DownloadStatus.completed,
      progress: 1,
      localPath: json['localPath'] as String?,
      completedAt: json['completedAt'] as int?,
      playlistId: json['playlistId'] as String?,
      playlistTitle: json['playlistTitle'] as String?,
      playlistThumbnailUrl: json['playlistThumbnailUrl'] as String?,
    );
  }
}

class PlaylistDownloadRecord {
  const PlaylistDownloadRecord({
    required this.playlistId,
    required this.title,
    required this.thumbnailUrl,
    required this.trackCount,
    required this.completedCount,
    required this.averageProgress,
    required this.startedAt,
    required this.trackIds,
    this.isPaused = false,
  });

  final String playlistId;
  final String title;
  final String thumbnailUrl;
  final int trackCount;
  final int completedCount;
  final double averageProgress;
  final int startedAt;
  final List<String> trackIds;
  final bool isPaused;

  PlaylistDownloadRecord copyWith({
    String? playlistId,
    String? title,
    String? thumbnailUrl,
    int? trackCount,
    int? completedCount,
    double? averageProgress,
    int? startedAt,
    List<String>? trackIds,
    bool? isPaused,
  }) {
    return PlaylistDownloadRecord(
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      trackCount: trackCount ?? this.trackCount,
      completedCount: completedCount ?? this.completedCount,
      averageProgress: averageProgress ?? this.averageProgress,
      startedAt: startedAt ?? this.startedAt,
      trackIds: trackIds ?? this.trackIds,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

class DownloadState {
  const DownloadState({
    this.activeDownloads = const {},
    this.activePlaylistDownloads = const {},
    this.completedDownloads = const [],
    this.isLoaded = false,
  });

  final Map<String, DownloadRecord> activeDownloads;
  final Map<String, PlaylistDownloadRecord> activePlaylistDownloads;
  final List<DownloadRecord> completedDownloads;
  final bool isLoaded;

  List<DownloadRecord> get orderedActiveDownloads {
    // Return all downloads that are NOT part of a playlist
    final items = activeDownloads.values
        .where((r) => r.playlistId == null)
        .toList(growable: false);
    items.sort(
      (a, b) => (b.startedAt ?? 0).compareTo(a.startedAt ?? 0),
    );
    return items;
  }

  List<PlaylistDownloadRecord> get orderedActivePlaylistDownloads {
    final items = activePlaylistDownloads.values.toList(growable: false);
    items.sort(
      (a, b) => b.startedAt.compareTo(a.startedAt),
    );
    return items;
  }

  DownloadRecord? recordForTrack(String? videoId) {
    if (videoId == null || videoId.isEmpty) {
      return null;
    }
    final activeRecord = activeDownloads[videoId];
    if (activeRecord != null) {
      return activeRecord;
    }

    for (final record in completedDownloads) {
      if (record.videoId == videoId) {
        return record;
      }
    }
    return null;
  }

  DownloadState copyWith({
    Map<String, DownloadRecord>? activeDownloads,
    Map<String, PlaylistDownloadRecord>? activePlaylistDownloads,
    List<DownloadRecord>? completedDownloads,
    bool? isLoaded,
  }) {
    return DownloadState(
      activeDownloads: activeDownloads ?? this.activeDownloads,
      activePlaylistDownloads: activePlaylistDownloads ?? this.activePlaylistDownloads,
      completedDownloads: completedDownloads ?? this.completedDownloads,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

const Object _unsetField = Object();
