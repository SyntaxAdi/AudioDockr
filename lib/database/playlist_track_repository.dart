import 'package:sqflite/sqflite.dart';
import 'database_manager.dart';
import 'track_repository.dart';
import 'models.dart';

class PlaylistTrackRepository {
  final DatabaseManager _dbManager;
  final TrackRepository _trackRepo;

  PlaylistTrackRepository(this._dbManager, this._trackRepo);

  Future<Database> get _database => _dbManager.database;

  Future<bool> addTrackToPlaylist({
    required String playlistId,
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
  }) async {
    final db = await _database;
    await _trackRepo.saveTrack(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
    );

    final existing = await db.query(
      'playlist_tracks',
      columns: ['video_id'],
      where: 'playlist_id = ? AND video_id = ?',
      whereArgs: [playlistId, videoId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return false;
    }

    final maxPositionResult = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) AS max_position '
      'FROM playlist_tracks WHERE playlist_id = ?',
      [playlistId],
    );
    final nextPosition =
        ((maxPositionResult.first['max_position'] as int?) ?? -1) + 1;

    await db.insert(
      'playlist_tracks',
      {
        'playlist_id': playlistId,
        'video_id': videoId,
        'position': nextPosition,
        'hidden': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return true;
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String videoId,
  }) async {
    final db = await _database;
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND video_id = ?',
      whereArgs: [playlistId, videoId],
    );
  }

  Future<void> setTrackHiddenInPlaylist({
    required String playlistId,
    required String videoId,
    required bool hidden,
  }) async {
    final db = await _database;
    await db.update(
      'playlist_tracks',
      {
        'hidden': hidden ? 1 : 0,
      },
      where: 'playlist_id = ? AND video_id = ?',
      whereArgs: [playlistId, videoId],
    );
  }

  Future<Set<String>> fetchPlaylistIdsForTrack(String videoId) async {
    final db = await _database;
    final result = await db.query(
      'playlist_tracks',
      columns: ['playlist_id'],
      where: 'video_id = ?',
      whereArgs: [videoId],
    );
    return result
        .map((row) => (row['playlist_id'] as String?) ?? '')
        .where((playlistId) => playlistId.isNotEmpty)
        .toSet();
  }

  Future<void> addTracksToPlaylistBulk({
    required String playlistId,
    required List<TrackWriteData> tracks,
  }) async {
    if (tracks.isEmpty) {
      return;
    }

    final db = await _database;
    await db.transaction((txn) async {
      final maxPositionResult = await txn.rawQuery(
        'SELECT COALESCE(MAX(position), -1) AS max_position '
        'FROM playlist_tracks WHERE playlist_id = ?',
        [playlistId],
      );
      var nextPosition =
          ((maxPositionResult.first['max_position'] as int?) ?? -1) + 1;

      for (final track in tracks) {
        await _trackRepo.upsertTrack(txn, track);
        await txn.insert(
          'playlist_tracks',
          {
            'playlist_id': playlistId,
            'video_id': track.videoId,
            'position': nextPosition,
            'hidden': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        nextPosition++;
      }
    });
  }

  Future<List<StoredTrack>> fetchPlaylistTracks(String playlistId) async {
    final db = await _database;
    final result = await db.rawQuery('''
      SELECT t.video_id, t.video_url, t.title, t.artist, t.duration,
             t.thumbnail_url, t.state, t.last_played_at,
             pt.hidden AS hidden_in_playlist
      FROM playlist_tracks pt
      INNER JOIN tracks t ON t.video_id = pt.video_id
      WHERE pt.playlist_id = ?
      ORDER BY pt.position ASC
    ''', [playlistId]);
    return result.map(StoredTrack.fromMap).toList();
  }
}
