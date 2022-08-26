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
}
