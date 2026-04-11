import '../database_helper.dart';
import '../services/spotify_import_service.dart';
import 'library_notifier.dart';

mixin LibrarySpotifyMixin on LibraryNotifierBase {
  Future<String> importSpotifyPlaylist(List<SpotifyImportTrack> tracks) async {
    if (tracks.isEmpty) return '';

    final playlistName = 'Spotify Playlist ${_nextSpotifyPlaylistNumber()}';
    final playlistId = await db.createPlaylist(playlistName);

    final importSeed = DateTime.now().millisecondsSinceEpoch;
    final importedTracks = [
      for (var i = 0; i < tracks.length; i++)
        TrackWriteData(
          videoId: 'spotify_import_${importSeed}_$i',
          videoUrl: '',
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

  int _nextSpotifyPlaylistNumber() {
    final pattern = RegExp(r'^Spotify Playlist (\d+)$');
    var max = 0;
    for (final playlist in state.userPlaylists) {
      final n =
          int.tryParse(pattern.firstMatch(playlist.name)?.group(1) ?? '');
      if (n != null && n > max) max = n;
    }
    return max + 1;
  }
}
