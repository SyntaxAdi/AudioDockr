import '../database_helper.dart';
import '../services/playlist_import_models.dart';
import 'library_notifier.dart';

mixin LibraryYoutubeMixin on LibraryNotifierBase {
  Future<String> importYoutubePlaylist(List<PlaylistImportTrack> tracks) async {
    if (tracks.isEmpty) return '';

    final playlistName = 'YouTube Playlist ${_nextYoutubePlaylistNumber()}';
    final playlistId = await db.createPlaylist(playlistName);

    final importSeed = DateTime.now().millisecondsSinceEpoch;
    final importedTracks = [
      for (var i = 0; i < tracks.length; i++)
        TrackWriteData(
          videoId: _videoIdFromYoutubeUrl(tracks[i].videoUrl) ??
              'youtube_import_${importSeed}_$i',
          videoUrl: tracks[i].videoUrl,
          title: tracks[i].songName,
          artist: tracks[i].artistName,
          durationSeconds: 0,
          thumbnailUrl: tracks[i].thumbnailUrl,
          lastPlayedAt: 0,
        ),
    ];

    await db.addTracksToPlaylistBulk(
      playlistId: playlistId,
      tracks: importedTracks,
    );

    await reloadAll();
    return playlistName;
  }

  int _nextYoutubePlaylistNumber() {
    final pattern = RegExp(r'^YouTube Playlist (\d+)$');
    var max = 0;
    for (final playlist in state.userPlaylists) {
      final n =
          int.tryParse(pattern.firstMatch(playlist.name)?.group(1) ?? '');
      if (n != null && n > max) max = n;
    }
    return max + 1;
  }

  String? _videoIdFromYoutubeUrl(String videoUrl) {
    final uri = Uri.tryParse(videoUrl);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    if (host.endsWith('youtube.com')) {
      final videoId = uri.queryParameters['v'];
      if (videoId != null && videoId.isNotEmpty) return videoId;
    }
    return null;
  }
}
