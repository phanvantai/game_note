import 'package:game_note/offline/data/database/database_manager.dart';
import 'package:game_note/offline/data/database/player_stats_manager.dart';
import 'package:game_note/offline/data/database/round_manager.dart';
import 'package:game_note/offline/domain/entities/league_model.dart';
import 'package:sqflite/sqflite.dart';

extension LeagueManagerX on DatabaseManager {
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
    final List<Map<String, dynamic>> maps =
        (await db.query(leaguesTable)).reversed.toList();

    return List.generate(
      maps.length,
      (index) => LeagueModel(
        id: maps[index][DBTableColumn.leagueId],
        name: maps[index][DBTableColumn.fullname],
        dateTime: DateTime.parse(maps[index][DBTableColumn.datetime]),
      ),
    );
  }

  Future<LeagueModel?> getLeague(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(leaguesTable, where: '${DBTableColumn.leagueId} = $id');
    var playersStats = await getPlayerStats(id);
    var rounds = await getRounds(id);
    return maps.isEmpty
        ? null
        : LeagueModel(
            id: maps.first[DBTableColumn.leagueId],
            name: maps.first[DBTableColumn.fullname],
            players: playersStats,
            rounds: rounds,
            dateTime: DateTime.parse(maps.first[DBTableColumn.datetime]),
          );
  }

  Future<int> deleteLeague(int leagueId) async {
    final db = await database;
    // delete rounds
    await deleteRoundsWithLeagueId(leagueId);
    // delete player league
    await deletePlayersStatsWithLeagueId(leagueId);
    return await db.delete(
      leaguesTable,
      where: '${DBTableColumn.leagueId} = ?',
      whereArgs: [leagueId],
    );
  }
}
