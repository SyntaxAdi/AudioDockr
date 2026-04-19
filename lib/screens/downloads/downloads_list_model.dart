import '../../download_manager/download_models.dart';

enum DownloadListItemType {
  header,
  playlist,
  playlistTrack,
  singleDownload,
  completedPlaylist,
  completedDownload,
  empty,
}

class DownloadListItem {
  final DownloadListItemType type;
  final String? label;
  final PlaylistDownloadRecord? playlist;
  final DownloadRecord? track;
  final String? playlistId;
  final String? playlistTitle;
  final String? thumbnailUrl;

  DownloadListItem({
    required this.type,
    this.label,
    this.playlist,
    this.track,
    this.playlistId,
    this.playlistTitle,
    this.thumbnailUrl,
  });
}
