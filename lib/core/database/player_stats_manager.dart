import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';
import 'package:sqflite/sqflite.dart';

extension PlayerStatsManager on DatabaseManager {
  Future<int> createPlayerStats(PlayerStatsModel stats) async {
    final db = await database;
    return await db.insert(
      playerLeagueTable,
      stats.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
