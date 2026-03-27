import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('audiodockr.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE url_cache (
        video_id TEXT PRIMARY KEY,
        audio_url TEXT,
        expires_at INTEGER,
        last_verified INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE tracks (
        video_id TEXT PRIMARY KEY,
        title TEXT,
        artist TEXT,
        duration INTEGER,
        thumbnail_url TEXT,
        liked INTEGER,
        state TEXT
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
  }
}
