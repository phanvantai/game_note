import 'package:game_note/model/player.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseManager {
  final String playerTable = "players";
  final String twoPlayerGames = "two_player_games";
  final String twoPlayerRounds = "two_player_rounds";
  late Future<Database> database;
  Future<void> open() async {
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'game_note_database.db'),
      onCreate: (db, version) {
        return db.execute(
            'CREATE TABLE IF NOT EXISTS $playerTable(id INTEGER PRIMARY KEY AUTOINCREMENT, fullname TEXT, level TEXT)');
      },
      version: 1,
    );
    createTwoPlayerGamesTable();
    createTwoPlayerRoundsTable();
  }

  Future<void> createTwoPlayerGamesTable() async {
    var db = await database;
    return db.execute(
        'CREATE TABLE IF NOT EXISTS $twoPlayerGames(id INTEGER PRIMARY KEY AUTOINCREMENT, player1 INTEGER, player2 INTEGER, score1 INTEGER, score2 INTEGER, photoUrl TEXT');
  }

  Future<void> createTwoPlayerRoundsTable() async {
    var db = await database;
    return db.execute(
        'CREATE TABLE IF NOT EXISTS $twoPlayerRounds(id INTEGER PRIMARY KEY AUTOINCREMENT, player1 INTEGER, player2 INTEGER, games TEXT');
  }

  Future<void> insertPlayer(Player player) async {
    final db = await database;
    await db.insert(
      playerTable,
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Player>> players() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(playerTable);
    return List.generate(maps.length, (i) {
      return Player(
        id: maps[i]['id'],
        fullname: maps[i]['fullname'],
        level: maps[i]['level'],
      );
    });
  }

  Future<void> updatePlayer(Player player) async {
    final db = await database;
    await db.update(
      playerTable,
      player.toMap(),
      where: 'fullname = ?',
      whereArgs: [player.fullname],
    );
  }

  Future<void> deletePlayer(Player player) async {
    final db = await database;
    await db.delete(
      playerTable,
      where: 'fullname = ?',
      whereArgs: [player.fullname],
    );
  }
}
