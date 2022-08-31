import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/domain/entities/round_model.dart';
import 'package:sqflite/sqflite.dart';

extension RoundManager on DatabaseManager {
  Future<int> createRound(RoundModel round) async {
    final db = await database;
    return await db.insert(
      roundsTable,
      round.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RoundModel>> getRounds(int leagueId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(roundsTable,
        where: '${DBTableColumn.leagueId} = $leagueId');
    List<RoundModel> list = [];
    for (var element in maps) {
      var id = element[DBTableColumn.roundId];
      // get matches with roundId

      list.add(RoundModel(
        leagueId: element[DBTableColumn.leagueId],
        id: id,
      ));
    }
    return list;
  }
}
