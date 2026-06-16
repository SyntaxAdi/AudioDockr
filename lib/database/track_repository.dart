import 'package:sqflite/sqflite.dart';
import 'database_manager.dart';
import 'models.dart';
import '../library/library_state.dart' show likedPlaylistId;

class TrackRepository {
  final DatabaseManager _dbManager;

  TrackRepository(this._dbManager);

  Future<Database> get _database => _dbManager.database;

  Future<void> saveTrack({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
  }) async {
    final db = await _database;
    await upsertTrack(
      db,
      TrackWriteData(
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        artist: artist,
        durationSeconds: durationSeconds,
        thumbnailUrl: thumbnailUrl,
        lastPlayedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> updateTrackVideoUrl({
    required String videoId,
    required String videoUrl,
  }) async {
    final db = await _database;
    await db.update(
      'tracks',
      {
        'video_url': videoUrl,
      },
      where: 'video_id = ?',
      whereArgs: [videoId],
    );
  }

  Future<void> setTrackReaction({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
    required String reaction,
  }) async {
    final db = await _database;
    await saveTrack(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
    );

    await db.update(
      'tracks',
      {
        'liked': reaction == 'liked' ? 1 : 0,
        'state': reaction,
      },
      where: 'video_id = ?',
      whereArgs: [videoId],
    );

    if (reaction == 'liked') {
      final maxPositionResult = await db.rawQuery(
        'SELECT COALESCE(MAX(position), -1) AS max_position '
        'FROM playlist_tracks WHERE playlist_id = ?',
        [likedPlaylistId],
      );
      final nextPosition =
          ((maxPositionResult.first['max_position'] as int?) ?? -1) + 1;

      await db.insert(
        'playlist_tracks',
        {
          'playlist_id': likedPlaylistId,
          'video_id': videoId,
          'position': nextPosition,
          'hidden': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } else {
      await db.delete(
        'playlist_tracks',
        where: 'playlist_id = ? AND video_id = ?',
        whereArgs: [likedPlaylistId, videoId],
      );
    }
  }

  Future<List<StoredTrack>> fetchAllTracks() async {
    final db = await _database;
    final result = await db.query(
      'tracks',
      orderBy: 'rowid DESC',
    );
    return result.map(StoredTrack.fromMap).toList();
  }

  Future<List<StoredTrack>> fetchLikedTracks() async {
    final db = await _database;
    final result = await db.rawQuery('''
      SELECT t.video_id, t.video_url, t.title, t.artist, t.duration,
             t.thumbnail_url, t.state, 0 AS hidden_in_playlist
      FROM playlist_tracks pt
      INNER JOIN tracks t ON t.video_id = pt.video_id
      WHERE pt.playlist_id = ?
      ORDER BY pt.position DESC
    ''', [likedPlaylistId]);
    return result.map(StoredTrack.fromMap).toList();
  }

  Future<List<StoredTrack>> fetchRecentlyPlayed({int? limit}) async {
    final db = await _database;
    final result = await db.query(
      'tracks',
      where: 'last_played_at > 0',
      orderBy: 'last_played_at DESC',
      limit: limit,
    );
    return result.map(StoredTrack.fromMap).toList();
  }

  Future<void> upsertTrack(
    DatabaseExecutor db,
    TrackWriteData track,
  ) async {
    await db.rawInsert(
      '''
      INSERT INTO tracks (
        video_id,
        video_url,
        title,
        artist,
        duration,
        thumbnail_url,
        liked,
        state,
        last_played_at
      ) VALUES (?, ?, ?, ?, ?, ?, 0, 'neutral', ?)
      ON CONFLICT(video_id) DO UPDATE SET
        video_url = excluded.video_url,
        title = excluded.title,
        artist = excluded.artist,
        duration = excluded.duration,
        thumbnail_url = excluded.thumbnail_url,
        last_played_at = excluded.last_played_at
      ''',
      [
        track.videoId,
        track.videoUrl,
        track.title,
        track.artist,
        track.durationSeconds,
        track.thumbnailUrl,
        track.lastPlayedAt,
      ],
    );
  }
}
