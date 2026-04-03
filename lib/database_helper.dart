import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

const String likedPlaylistId = 'liked';

class StoredTrack {
  const StoredTrack({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.thumbnailUrl,
    required this.reaction,
    required this.lastPlayedAt,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final int durationSeconds;
  final String thumbnailUrl;
  final String reaction;
  final int lastPlayedAt;

  bool get isLiked => reaction == 'liked';
  bool get isDisliked => reaction == 'disliked';

  factory StoredTrack.fromMap(Map<String, Object?> map) {
    return StoredTrack(
      videoId: (map['video_id'] as String?) ?? '',
      videoUrl: (map['video_url'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'Unknown title',
      artist: (map['artist'] as String?) ?? 'Unknown artist',
      durationSeconds: (map['duration'] as int?) ?? 0,
      thumbnailUrl: (map['thumbnail_url'] as String?) ?? '',
      reaction: (map['state'] as String?) ?? 'neutral',
      lastPlayedAt: (map['last_played_at'] as int?) ?? 0,
    );
  }
}

class StoredPlaylist {
  const StoredPlaylist({
    required this.id,
    required this.name,
    required this.trackCount,
    required this.coverImagePath,
  });

  final String id;
  final String name;
  final int trackCount;
  final String coverImagePath;
}

class TrackWriteData {
  const TrackWriteData({
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.thumbnailUrl,
    this.lastPlayedAt = 0,
  });

  final String videoId;
  final String videoUrl;
  final String title;
  final String artist;
  final int durationSeconds;
  final String thumbnailUrl;
  final int lastPlayedAt;
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB('audiodockr.db');
    await _ensureBuiltinPlaylists(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tracks (
        video_id TEXT PRIMARY KEY,
        video_url TEXT,
        title TEXT,
        artist TEXT,
        duration INTEGER,
        thumbnail_url TEXT,
        liked INTEGER DEFAULT 0,
        state TEXT DEFAULT 'neutral',
        last_played_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT,
        cover_image_path TEXT DEFAULT '',
        created_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_tracks (
        playlist_id TEXT,
        video_id TEXT,
        position INTEGER,
        PRIMARY KEY(playlist_id, video_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE search_history (
        query TEXT PRIMARY KEY,
        searched_at INTEGER
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_playlist_tracks_playlist_position '
      'ON playlist_tracks(playlist_id, position)',
    );
    await db.execute(
      'CREATE INDEX idx_tracks_last_played_at ON tracks(last_played_at)',
    );
    await db.execute(
      'CREATE INDEX idx_search_history_searched_at ON search_history(searched_at)',
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS url_cache');
      await _ensureColumn(db, 'tracks', 'video_url', 'TEXT');
      await db.execute(
        "UPDATE tracks SET state = CASE WHEN liked = 1 THEN 'liked' "
        "WHEN state IS NULL OR state = '' THEN 'neutral' ELSE state END",
      );
    }
    if (oldVersion < 3) {
      await _ensureColumn(
        db,
        'tracks',
        'last_played_at',
        'INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS search_history (
          query TEXT PRIMARY KEY,
          searched_at INTEGER
        )
      ''');
    }
    if (oldVersion < 5) {
      await _ensureColumn(
        db,
        'playlists',
        'cover_image_path',
        "TEXT DEFAULT ''",
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_playlist_tracks_playlist_position '
        'ON playlist_tracks(playlist_id, position)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tracks_last_played_at '
        'ON tracks(last_played_at)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_search_history_searched_at '
        'ON search_history(searched_at)',
      );
    }
  }

  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((entry) => entry['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _ensureBuiltinPlaylists(Database db) async {
    await db.insert(
      'playlists',
      {
        'id': likedPlaylistId,
        'name': 'Liked',
        'cover_image_path': '',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<String> createPlaylist(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return '';
    }

    final db = await database;
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

    final db = await database;
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

  Future<bool> addTrackToPlaylist({
    required String playlistId,
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
  }) async {
    final db = await database;
    await saveTrack(
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
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return true;
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String videoId,
  }) async {
    final db = await database;
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND video_id = ?',
      whereArgs: [playlistId, videoId],
    );
  }

  Future<Set<String>> fetchPlaylistIdsForTrack(String videoId) async {
    final db = await database;
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

  Future<void> saveTrack({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
  }) async {
    final db = await database;
    await _upsertTrack(
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

  Future<void> addTracksToPlaylistBulk({
    required String playlistId,
    required List<TrackWriteData> tracks,
  }) async {
    if (tracks.isEmpty) {
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      final maxPositionResult = await txn.rawQuery(
        'SELECT COALESCE(MAX(position), -1) AS max_position '
        'FROM playlist_tracks WHERE playlist_id = ?',
        [playlistId],
      );
      var nextPosition =
          ((maxPositionResult.first['max_position'] as int?) ?? -1) + 1;

      for (final track in tracks) {
        await _upsertTrack(txn, track);
        await txn.insert(
          'playlist_tracks',
          {
            'playlist_id': playlistId,
            'video_id': track.videoId,
            'position': nextPosition,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        nextPosition++;
      }
    });
  }

  Future<void> updateTrackVideoUrl({
    required String videoId,
    required String videoUrl,
  }) async {
    final db = await database;
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
    final db = await database;
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
    final db = await database;
    final result = await db.query(
      'tracks',
      orderBy: 'rowid DESC',
    );
    return result.map(StoredTrack.fromMap).toList();
  }

  Future<List<StoredTrack>> fetchLikedTracks() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT t.video_id, t.video_url, t.title, t.artist, t.duration,
             t.thumbnail_url, t.state
      FROM playlist_tracks pt
      INNER JOIN tracks t ON t.video_id = pt.video_id
      WHERE pt.playlist_id = ?
      ORDER BY pt.position DESC
    ''', [likedPlaylistId]);
    return result.map(StoredTrack.fromMap).toList();
  }

  Future<List<StoredTrack>> fetchPlaylistTracks(String playlistId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT t.video_id, t.video_url, t.title, t.artist, t.duration,
             t.thumbnail_url, t.state, t.last_played_at
      FROM playlist_tracks pt
      INNER JOIN tracks t ON t.video_id = pt.video_id
      WHERE pt.playlist_id = ?
      ORDER BY pt.position ASC
    ''', [playlistId]);
    return result.map(StoredTrack.fromMap).toList();
  }

  Future<List<StoredTrack>> fetchRecentlyPlayed({int limit = 8}) async {
    final db = await database;
    final result = await db.query(
      'tracks',
      where: 'last_played_at > 0',
      orderBy: 'last_played_at DESC',
      limit: limit,
    );
    return result.map(StoredTrack.fromMap).toList();
  }

  Future<List<StoredPlaylist>> fetchPlaylists() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.id, p.name, p.cover_image_path, COUNT(pt.video_id) AS track_count
      FROM playlists p
      LEFT JOIN playlist_tracks pt ON pt.playlist_id = p.id
      GROUP BY p.id, p.name, p.cover_image_path
      ORDER BY CASE WHEN p.id = ? THEN 0 ELSE 1 END, p.created_at ASC
    ''', [likedPlaylistId]);

    return result
        .map(
          (map) => StoredPlaylist(
            id: (map['id'] as String?) ?? '',
            name: (map['name'] as String?) ?? '',
            trackCount: (map['track_count'] as int?) ?? 0,
            coverImagePath: (map['cover_image_path'] as String?) ?? '',
          ),
        )
        .toList();
  }

  Future<void> saveSearchQuery(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return;
    }

    final db = await database;
    await db.insert(
      'search_history',
      {
        'query': trimmedQuery,
        'searched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> fetchSearchHistory({int limit = 12}) async {
    final db = await database;
    final result = await db.query(
      'search_history',
      orderBy: 'searched_at DESC',
      limit: limit,
    );
    return result
        .map((row) => (row['query'] as String?) ?? '')
        .where((query) => query.isNotEmpty)
        .toList();
  }

  Future<void> _upsertTrack(
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
