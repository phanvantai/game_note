import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/domain/entities/player_model.dart';
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

  Future<List<PlayerStatsModel>> getPlayerStats(int leagueId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(playerLeagueTable,
        where: '${DBTableColumn.leagueId} = $leagueId');

    List<PlayerStatsModel> list = [];
    for (var element in maps) {
      int playerId = element[DBTableColumn.playerId];
      int leagueId = element[DBTableColumn.leagueId];
      PlayerModel? playerModel = await player(playerId);
      if (playerModel == null) {
        continue;
      }
      list.add(
        PlayerStatsModel(
          id: element[DBTableColumn.playerLeagueId],
          playerModel: playerModel,
          leagueId: leagueId,
          totalPlayed: element[DBTableColumn.playerLeagueTotal],
          wins: element[DBTableColumn.playerLeagueWins],
          draws: element[DBTableColumn.playerLeagueDraws],
          losses: element[DBTableColumn.playerLeagueLosses],
          goalDifferent: element[DBTableColumn.playerLeagueGD],
          points: element[DBTableColumn.playerLeaguePoints],
        ),
      );
    }
    return list;
  }
}
