import 'package:game_note/features/offline/data/database/database_manager.dart';
import 'package:game_note/features/offline/domain/entities/player_model.dart';
import 'package:game_note/features/offline/domain/entities/player_stats_model.dart';
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
    final List<Map<String, dynamic>> maps = await db.query(
      playerLeagueTable,
      where: '${DBTableColumn.leagueId} = $leagueId',
    );

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
    list.sort((a, b) {
      if (a.points > b.points) {
        return -1;
      } else if (a.points < b.points) {
        return 1;
      } else {
        if (a.goalDifferent > b.goalDifferent) {
          return -1;
        } else if (a.goalDifferent < b.goalDifferent) {
          return 1;
        } else {
          if (a.totalPlayed > b.totalPlayed) {
            return -1;
          } else if (a.totalPlayed < b.totalPlayed) {
            return 1;
          } else {
            return 0;
          }
        }
      }
    });

    return list;
  }

  Future<void> updatePlayerStats(PlayerStatsModel model) async {
    final db = await database;
    await db.update(
      playerLeagueTable,
      model.toMap(),
      where: '${DBTableColumn.playerLeagueId} = ?',
      whereArgs: [model.id],
    );
  }

  Future<int> deletePlayerStatsWithId(int playerStatsId) async {
    final db = await database;
    return db.delete(
      playerLeagueTable,
      where: '${DBTableColumn.playerLeagueId} = ?',
      whereArgs: [playerStatsId],
    );
  }

  Future<void> deletePlayersStatsWithLeagueId(int leagueId) async {
    final playersStats = await getPlayerStats(leagueId);
    for (var element in playersStats) {
      if (element.id != null) {
        await deletePlayerStatsWithId(element.id!);
      }
    }
  }

  Future<PlayerStatsModel> getPlayerStat(int playerStatsId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      playerLeagueTable,
      where: '${DBTableColumn.playerLeagueId} = $playerStatsId',
    );
    if (maps.isEmpty) {
      throw 'empty data in db';
    }
    int playerId = maps.first[DBTableColumn.playerId];
    PlayerModel? playerModel = await player(playerId);
    if (playerModel == null) {
      throw 'get player model error';
    }

    return PlayerStatsModel(
      id: maps.first[DBTableColumn.playerLeagueId],
      playerModel: playerModel,
      leagueId: maps.first[DBTableColumn.leagueId],
      totalPlayed: maps.first[DBTableColumn.playerLeagueTotal],
      wins: maps.first[DBTableColumn.playerLeagueWins],
      draws: maps.first[DBTableColumn.playerLeagueDraws],
      losses: maps.first[DBTableColumn.playerLeagueLosses],
      goalDifferent: maps.first[DBTableColumn.playerLeagueGD],
      points: maps.first[DBTableColumn.playerLeaguePoints],
    );
  }
}
