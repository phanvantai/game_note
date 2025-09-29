import 'package:pes_arena/offline/data/database/database_manager.dart';
import 'package:pes_arena/offline/data/database/match_manager.dart';
import 'package:pes_arena/offline/domain/entities/match_model.dart';
import 'package:pes_arena/offline/domain/entities/round_model.dart';
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
      List<MatchModel> matches = await getMatches(id);
      list.add(RoundModel(
        leagueId: element[DBTableColumn.leagueId],
        id: id,
        matches: matches,
      ));
    }
    return list;
  }

  Future<int> deleteRoundWithId(int roundId) async {
    final db = await database;
    // delete matchs
    await deleteMatchsWithRoundId(roundId);
    return db.delete(
      roundsTable,
      where: '${DBTableColumn.roundId} = ?',
      whereArgs: [roundId],
    );
  }

  Future<void> deleteRoundsWithLeagueId(int leagueId) async {
    // get rounds
    final rounds = await getRounds(leagueId);
    for (var element in rounds) {
      if (element.id != null) {
        await deleteRoundWithId(element.id!);
      }
    }
  }
}
