import 'package:sqflite/sqflite.dart';
import 'database_manager.dart';
import 'models.dart';
import '../library/library_state.dart' show likedPlaylistId;

class PlaylistRepository {
  final DatabaseManager _dbManager;

  PlaylistRepository(this._dbManager);

  Future<Database> get _database => _dbManager.database;

  Future<String> createPlaylist(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return '';
    }

    final db = await _database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final playlistId = 'playlist_$timestamp';
    await db.insert(
      'playlists',
      {
        'id': playlistId,
        'name': trimmedName,
        'cover_image_path': '',
        'created_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return playlistId;
  }

  Future<void> updatePlaylist({
    required String playlistId,
    required String name,
    required String coverImagePath,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final db = await _database;
    await db.update(
      'playlists',
      {
        'name': trimmedName,
        'cover_image_path': coverImagePath,
      },
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> togglePinPlaylist(String playlistId, bool isPinned) async {
    final db = await _database;
    await db.update(
      'playlists',
      {'is_pinned': isPinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  Future<void> deletePlaylist(String playlistId) async {
    if (playlistId == likedPlaylistId) {
      return;
    }

    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete(
        'playlist_tracks',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      await txn.delete(
        'playlists',
        where: 'id = ?',
        whereArgs: [playlistId],
      );
      await txn.delete(
        'recent_playlists',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      await txn.delete(
        'tracks',
        where:
            "video_id NOT IN (SELECT DISTINCT video_id FROM playlist_tracks) "
            "AND state = 'neutral' AND last_played_at = 0",
      );
    });
  }

  Future<void> recordPlaylistOpened(String playlistId) async {
    final trimmedId = playlistId.trim();
    if (trimmedId.isEmpty) {
      return;
    }

    final db = await _database;
    await db.insert(
      'recent_playlists',
      {
        'playlist_id': trimmedId,
        'last_opened_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StoredPlaylist>> fetchRecentlyOpenedPlaylists({int? limit}) async {
    final db = await _database;
    final result = await db.rawQuery('''
      SELECT p.id,
             p.name,
             p.cover_image_path,
             COUNT(pt.video_id) AS track_count,
             rp.last_opened_at
      FROM recent_playlists rp
      INNER JOIN playlists p ON p.id = rp.playlist_id
      LEFT JOIN playlist_tracks pt ON pt.playlist_id = p.id
      GROUP BY p.id, p.name, p.cover_image_path, rp.last_opened_at
      ORDER BY rp.last_opened_at DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''');

    return result
        .map(
          (map) => StoredPlaylist(
            id: (map['id'] as String?) ?? '',
            name: (map['name'] as String?) ?? '',
            trackCount: (map['track_count'] as int?) ?? 0,
            coverImagePath: (map['cover_image_path'] as String?) ?? '',
            lastOpenedAt: (map['last_opened_at'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  Future<List<StoredPlaylist>> fetchPlaylists() async {
    final db = await _database;
    final result = await db.rawQuery('''
      SELECT p.id, p.name, p.cover_image_path, p.is_pinned, COUNT(pt.video_id) AS track_count
      FROM playlists p
      LEFT JOIN playlist_tracks pt ON pt.playlist_id = p.id
      GROUP BY p.id, p.name, p.cover_image_path, p.is_pinned
      ORDER BY 
        CASE WHEN p.id = ? THEN 0 ELSE 1 END,
        p.is_pinned DESC,
        p.created_at ASC
    ''', [likedPlaylistId]);

    return result
        .map(
          (map) => StoredPlaylist(
            id: (map['id'] as String?) ?? '',
            name: (map['name'] as String?) ?? '',
            trackCount: (map['track_count'] as int?) ?? 0,
            coverImagePath: (map['cover_image_path'] as String?) ?? '',
            isPinned: ((map['is_pinned'] as int?) ?? 0) == 1,
            lastOpenedAt: 0,
          ),
        )
        .toList();
  }
}
