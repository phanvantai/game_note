import 'package:pes_arena/offline/data/database/database_manager.dart';
import 'package:pes_arena/offline/data/database/result_manager.dart';
import 'package:pes_arena/offline/domain/entities/match_model.dart';
import 'package:pes_arena/offline/domain/entities/result_model.dart';
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

  Future<MatchModel> getMatch(int matchId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(matchesTable,
        where: '${DBTableColumn.matchId} = $matchId');
    if (maps.isEmpty) {
      throw 'empty data from database';
    }
    List<ResultModel> results = await getResults(matchId);
    if (results.length < 2) {
      throw 'result of match is error';
    }
    return MatchModel(
      id: matchId,
      roundId: maps.first[DBTableColumn.roundId],
      status: maps.first[DBTableColumn.matchStatus] == 1 ? true : false,
      created: maps.first[DBTableColumn.datetime],
      home: results[0],
      away: results[1],
    );
  }

  Future<void> updateMatch(MatchModel matchModel) async {
    final db = await database;
    await db.update(
      matchesTable,
      matchModel.toMap(),
      where: '${DBTableColumn.matchId} = ?',
      whereArgs: [matchModel.id],
    );
  }

  Future<int> deleteMatchWithId(int matchId) async {
    final db = await database;
    // delete player match
    await deletePlayersMatchWithMatchId(matchId);
    return db.delete(matchesTable,
        where: '${DBTableColumn.matchId} = ?', whereArgs: [matchId]);
  }

  Future<void> deleteMatchsWithRoundId(int roundId) async {
    final matchs = await getMatches(roundId);
    for (var element in matchs) {
      if (element.id != null) {
        await deleteMatchWithId(element.id!);
      }
    }
  }
}
