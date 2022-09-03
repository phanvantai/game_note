import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/core/database/result_manager.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/result_model.dart';
import 'package:sqflite/sqflite.dart';

extension MatchManager on DatabaseManager {
  Future<int> createMatch(MatchModel model) async {
    final db = await database;
    return await db.insert(
      matchesTable,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MatchModel>> getMatches(int roundId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      matchesTable,
      where: '${DBTableColumn.roundId} = $roundId',
    );
    List<MatchModel> list = [];
    for (var element in maps) {
      int id = element[DBTableColumn.matchId];
      int roundId = element[DBTableColumn.roundId];
      List<ResultModel> results = await getResults(id);
      if (results.length < 2) {
        continue;
      }
      list.add(MatchModel(
        id: id,
        roundId: roundId,
        status: element[DBTableColumn.matchStatus] == 1 ? true : false,
        created: element[DBTableColumn.datetime],
        home: results[0],
        away: results[1],
      ));
    }
    return list;
  }
}
