import 'package:game_note/offline/data/database/database_manager.dart';
import 'package:game_note/offline/domain/entities/player_model.dart';
import 'package:game_note/offline/domain/entities/result_model.dart';
import 'package:sqflite/sqflite.dart';

extension ResultManager on DatabaseManager {
  Future<int> createResult(ResultModel model) async {
    final db = await database;
    return await db.insert(
      playerMatchTable,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ResultModel>> getResults(int matchId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(playerMatchTable,
        where: '${DBTableColumn.matchId} = $matchId');
    List<ResultModel> list = [];
    for (var element in maps) {
      int playerId = element[DBTableColumn.playerId];
      int matchId = element[DBTableColumn.matchId];
      PlayerModel? playerModel = await player(playerId);
      if (playerModel == null) {
        continue;
      }
      list.add(
        ResultModel(
          id: element[DBTableColumn.playerMatchId],
          matchId: matchId,
          playerModel: playerModel,
          score: element[DBTableColumn.playerMatchPlayerScore],
        ),
      );
    }
    return list;
  }

  Future<ResultModel?> getResult(int resultId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(playerMatchTable,
        where: '${DBTableColumn.playerMatchId} = $resultId');
    if (maps.isEmpty) {
      return null;
    }
    var playerId = maps.first[DBTableColumn.playerId];
    var playerModel = await player(playerId);
    return playerModel == null
        ? null
        : ResultModel(
            id: maps.first[DBTableColumn.playerMatchId],
            matchId: maps.first[DBTableColumn.matchId],
            score: maps.first[DBTableColumn.playerMatchPlayerScore],
            playerModel: playerModel);
  }

  Future<void> updateResult(ResultModel resultModel) async {
    final db = await database;
    await db.update(
      playerMatchTable,
      resultModel.toMap(),
      where: '${DBTableColumn.playerMatchId} = ?',
      whereArgs: [resultModel.id],
    );
  }

  Future<int> deletePlayerMatchWithId(int playerMatchId) async {
    final db = await database;
    return db.delete(
      playerMatchTable,
      where: '${DBTableColumn.playerMatchId} = ?',
      whereArgs: [playerMatchId],
    );
  }

  Future<void> deletePlayersMatchWithMatchId(int matchId) async {
    final playersMatch = await getResults(matchId);
    for (var element in playersMatch) {
      if (element.id != null) {
        await deletePlayerMatchWithId(element.id!);
      }
    }
  }
}
