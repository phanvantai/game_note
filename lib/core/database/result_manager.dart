import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/entities/result_model.dart';
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
}
