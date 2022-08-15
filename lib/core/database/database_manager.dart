import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/_old/model/two_player_game.dart';
import 'package:game_note/_old/model/two_player_round.dart';
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
      // onCreate: (db, version) {
      //   return db.execute(
      //       'CREATE TABLE IF NOT EXISTS $playerTable(id INTEGER PRIMARY KEY AUTOINCREMENT, fullname TEXT, level TEXT)');
      // },
      version: 1,
    );
    createTables();
  }

  Future<void> createTables() async {
    final db = await database;
    db.execute(
        'CREATE TABLE IF NOT EXISTS $playerTable(id INTEGER PRIMARY KEY AUTOINCREMENT, fullname TEXT, level TEXT)');
    db.execute(
        'CREATE TABLE IF NOT EXISTS $twoPlayerGames(id INTEGER PRIMARY KEY AUTOINCREMENT, player1 INTEGER, player2 INTEGER, score1 INTEGER, score2 INTEGER, photoUrl TEXT)');
    db.execute(
        'CREATE TABLE IF NOT EXISTS $twoPlayerRounds(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, player1 INTEGER, player2 INTEGER, games TEXT)');
  }

  Future<void> insertPlayer(PlayerModel player) async {
    final db = await database;
    await db.insert(
      playerTable,
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertTwoPlayerGame(TwoPlayerGame game) async {
    final db = await database;
    return await db.insert(
      twoPlayerGames,
      game.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertTwoPlayerRound(TwoPlayerRound round) async {
    final db = await database;
    return await db.insert(
      twoPlayerRounds,
      round.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PlayerModel>> players() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(playerTable);
    return List.generate(maps.length, (i) {
      return PlayerModel(
        id: maps[i]['id'],
        fullname: maps[i]['fullname'],
        level: maps[i]['level'],
      );
    });
  }

  Future<PlayerModel?> player(int? id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(playerTable, where: "id = $id");
    if (maps.isEmpty) {
      return null;
    }
    return PlayerModel(
      fullname: maps.first['fullname'],
      id: maps.first['id'],
      level: maps.first['level'],
    );
  }

  Future<List<TwoPlayerGame>> games() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(twoPlayerGames);
    List<TwoPlayerGame> abc = [];
    for (var map in maps) {
      int? id = map['id'];
      int? score1 = map['score1'];
      int? score2 = map['score2'];
      String? photoUrl = map['photoUrl'];
      int? player1Id = map['player1'] as int?;
      PlayerModel? player1 = await player(player1Id);
      int? player2Id = map['player2'] as int?;
      PlayerModel? player2 = await player(player2Id);
      if (player1 != null && player2 != null) {
        abc.add(TwoPlayerGame(
          player1: player1,
          player2: player2,
          score1: score1,
          score2: score2,
          photoUrl: photoUrl,
          id: id,
        ));
      }
    }
    return abc;
  }

  Future<TwoPlayerGame?> game(int? id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(twoPlayerGames, where: "id = $id");
    if (maps.isEmpty) {
      return null;
    }
    var map = maps.first;
    int? idRound = map['id'];
    int? score1 = map['score1'];
    int? score2 = map['score2'];
    String? photoUrl = map['photoUrl'];
    int? player1Id = map['player1'] as int?;
    PlayerModel? player1 = await player(player1Id);
    int? player2Id = map['player2'] as int?;
    PlayerModel? player2 = await player(player2Id);
    if (player1 != null && player2 != null) {
      var game = TwoPlayerGame(
        player1: player1,
        player2: player2,
        id: idRound,
        score1: score1,
        score2: score2,
        photoUrl: photoUrl,
      );
      return game;
    } else {
      return null;
    }
  }

  Future<List<TwoPlayerRound>> rounds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(twoPlayerRounds);
    List<TwoPlayerRound> abc = [];
    for (var map in maps) {
      int? id = map['id'];
      String? name = map['name'];
      String? games = map['games'];
      int? player1Id = map['player1'] as int?;
      PlayerModel? player1 = await player(player1Id);
      int? player2Id = map['player2'] as int?;
      PlayerModel? player2 = await player(player2Id);
      if (player1 != null && player2 != null) {
        var round = TwoPlayerRound(
          player1: player1,
          player2: player2,
          id: id,
        );
        if (games != null) {
          var list = games
              .split(",")
              .where((element) => element.isNotEmpty)
              .map((e) => int.parse(e))
              .toList();
          List<TwoPlayerGame> g = [];
          for (var id in list) {
            var _g = await game(id);
            if (_g != null) {
              g.add(_g);
            }
          }
          round.games = g;
        }
        round.name = name;
        abc.add(round);
      }
    }
    return abc;
  }

  Future<TwoPlayerRound?> round(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(twoPlayerRounds, where: "id = $id");
    if (maps.isEmpty) {
      return null;
    }
    var map = maps.first;
    int? idRound = map['id'];
    String? name = map['name'];
    String? games = map['games'];
    int? player1Id = map['player1'] as int?;
    PlayerModel? player1 = await player(player1Id);
    int? player2Id = map['player2'] as int?;
    PlayerModel? player2 = await player(player2Id);
    if (player1 != null && player2 != null) {
      var round = TwoPlayerRound(
        player1: player1,
        player2: player2,
        id: idRound,
      );
      if (games != null) {
        var list = games
            .split(",")
            .where((element) => element.isNotEmpty)
            .map((e) => int.parse(e))
            .toList();
        List<TwoPlayerGame> g = [];
        for (var id in list) {
          var _g = await game(id);
          if (_g != null) {
            g.add(_g);
          }
        }
        round.games = g;
      }
      round.name = name;
      return round;
    } else {
      return null;
    }
  }

  Future<void> updatePlayer(PlayerModel player) async {
    final db = await database;
    await db.update(
      playerTable,
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<void> updateRound(TwoPlayerRound round) async {
    final db = await database;
    await db.update(twoPlayerRounds, round.toMap(),
        where: 'id = ?', whereArgs: [round.id]);
  }

  Future<int> deletePlayer(PlayerModel player) async {
    final db = await database;
    return await db.delete(
      playerTable,
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }
}
