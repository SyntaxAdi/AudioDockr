import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../library/library_state.dart' show likedPlaylistId;

class DatabaseManager {
  static final DatabaseManager instance = DatabaseManager._init();
  static Database? _database;
  static Completer<Database>? _initCompleter;

  DatabaseManager._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (_initCompleter != null) return _initCompleter!.future;

    final completer = Completer<Database>();
    _initCompleter = completer;

    try {
      final db = await _initDB('audiodockr.db');
      _database = db;
      completer.complete(db);
      return db;
    } catch (e, stack) {
      _initCompleter = null;
      completer.completeError(e, stack);
      rethrow;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    
    await _ensureBuiltinPlaylists(db);
    
    return db;
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
        is_pinned INTEGER DEFAULT 0,
        created_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_tracks (
        playlist_id TEXT,
        video_id TEXT,
        position INTEGER,
        hidden INTEGER DEFAULT 0,
        PRIMARY KEY(playlist_id, video_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE search_history (
        query TEXT PRIMARY KEY,
        searched_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE recent_playlists (
        playlist_id TEXT PRIMARY KEY,
        last_opened_at INTEGER
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
    await db.execute(
      'CREATE INDEX idx_recent_playlists_last_opened_at '
      'ON recent_playlists(last_opened_at)',
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
    if (oldVersion < 7) {
      await _ensureColumn(
        db,
        'playlist_tracks',
        'hidden',
        'INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recent_playlists (
          playlist_id TEXT PRIMARY KEY,
          last_opened_at INTEGER
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recent_playlists_last_opened_at '
        'ON recent_playlists(last_opened_at)',
      );
    }
    if (oldVersion < 9) {
      await _ensureColumn(
        db,
        'playlists',
        'is_pinned',
        'INTEGER DEFAULT 0',
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
}
