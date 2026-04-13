enum DownloadStatus {
  downloading,
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

  bool get isDownloading => status == DownloadStatus.downloading;
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
    );
  }
}

class DownloadState {
  const DownloadState({
    this.activeDownloads = const {},
    this.completedDownloads = const [],
    this.isLoaded = false,
  });

  final Map<String, DownloadRecord> activeDownloads;
  final List<DownloadRecord> completedDownloads;
  final bool isLoaded;

  List<DownloadRecord> get orderedActiveDownloads {
    final items = activeDownloads.values.toList(growable: false);
    items.sort(
      (a, b) => (b.startedAt ?? 0).compareTo(a.startedAt ?? 0),
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
    List<DownloadRecord>? completedDownloads,
    bool? isLoaded,
  }) {
    return DownloadState(
      activeDownloads: activeDownloads ?? this.activeDownloads,
      completedDownloads: completedDownloads ?? this.completedDownloads,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

const Object _unsetField = Object();
