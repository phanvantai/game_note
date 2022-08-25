import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:sqflite/sql.dart';

extension LeagueManager on DatabaseManager {
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
    final List<Map<String, dynamic>> maps = await db.query(leaguesTable);

    return List.generate(
      maps.length,
      (index) => LeagueModel(
        id: maps[index]['id'],
        name: maps[index]['name'],
        dateTime: DateTime.parse(maps[index]['date_time']),
      ),
    );
  }

  Future<LeagueModel?> getLeague(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(leaguesTable, where: 'id = $id');
    // TODO: - get players
    // TODO: - get rounds
    return maps.isEmpty
        ? null
        : LeagueModel(
            id: maps.first['id'],
            name: maps.first['name'],
            dateTime: DateTime.parse(maps.first['date_time']),
          );
  }

  Future<int> deleteLeague(int id) async {
    final db = await database;
    return await db.delete(
      leaguesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
