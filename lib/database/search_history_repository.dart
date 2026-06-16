import 'package:sqflite/sqflite.dart';
import 'database_manager.dart';

class SearchHistoryRepository {
  final DatabaseManager _dbManager;

  SearchHistoryRepository(this._dbManager);

  Future<Database> get _database => _dbManager.database;

  Future<void> saveSearchQuery(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return;
    }

    final db = await _database;
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
    final db = await _database;
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
