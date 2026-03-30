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
  });

  final String id;
  final String name;
  final int trackCount;
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
      version: 4,
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
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> createPlaylist(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'playlists',
      {
        'id': 'playlist_$timestamp',
        'name': trimmedName,
        'created_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
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
    await db.insert(
      'tracks',
      {
        'video_id': videoId,
        'video_url': videoUrl,
        'title': title,
        'artist': artist,
        'duration': durationSeconds,
        'thumbnail_url': thumbnailUrl,
        'liked': 0,
        'state': 'neutral',
        'last_played_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.update(
      'tracks',
      {
        'video_url': videoUrl,
        'title': title,
        'artist': artist,
        'duration': durationSeconds,
        'thumbnail_url': thumbnailUrl,
        'last_played_at': DateTime.now().millisecondsSinceEpoch,
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
      SELECT p.id, p.name, COUNT(pt.video_id) AS track_count
      FROM playlists p
      LEFT JOIN playlist_tracks pt ON pt.playlist_id = p.id
      GROUP BY p.id, p.name
      ORDER BY CASE WHEN p.id = ? THEN 0 ELSE 1 END, p.created_at ASC
    ''', [likedPlaylistId]);

    return result
        .map(
          (map) => StoredPlaylist(
            id: (map['id'] as String?) ?? '',
            name: (map['name'] as String?) ?? '',
            trackCount: (map['track_count'] as int?) ?? 0,
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
}
