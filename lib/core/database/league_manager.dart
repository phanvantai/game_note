import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/core/database/player_stats_manager.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:sqflite/sqflite.dart';

extension LeagueManager on DatabaseManager {
  Future<int> createLeague(LeagueModel league) async {
    final db = await database;
    return await db.insert(
      leaguesTable,
      league.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LeagueModel>> getLeagues() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(leaguesTable);

    return List.generate(
      maps.length,
      (index) => LeagueModel(
        id: maps[index][DBTableColumn.leagueId],
        name: maps[index][DBTableColumn.fullname],
        dateTime: DateTime.parse(maps[index][DBTableColumn.dateTime]),
      ),
    );
  }

  Future<LeagueModel?> getLeague(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(leaguesTable, where: '${DBTableColumn.leagueId} = $id');
    // TODO: - get, rounds
    var playersStats = await getPlayerStats(id);
    return maps.isEmpty
        ? null
        : LeagueModel(
            id: maps.first[DBTableColumn.leagueId],
            name: maps.first[DBTableColumn.fullname],
            players: playersStats,
            dateTime: DateTime.parse(maps.first[DBTableColumn.dateTime]),
          );
  }

  Future<int> deleteLeague(int id) async {
    final db = await database;
    return await db.delete(
      leaguesTable,
      where: '${DBTableColumn.leagueId} = ?',
      whereArgs: [id],
    );
  }
}
