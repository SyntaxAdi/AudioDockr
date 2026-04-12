import '../../library/library_models.dart';

class RecentActivityItem {
  const RecentActivityItem._({
    this.track,
    this.playlist,
    required this.timestamp,
  });

  factory RecentActivityItem.track(LibraryTrack track) {
    return RecentActivityItem._(
      track: track,
      timestamp: track.lastPlayedAt,
    );
  }

  factory RecentActivityItem.playlist(LibraryPlaylist playlist) {
    return RecentActivityItem._(
      playlist: playlist,
      timestamp: playlist.lastOpenedAt,
    );
  }

  final LibraryTrack? track;
  final LibraryPlaylist? playlist;
  final int timestamp;
}
