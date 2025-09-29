import 'package:pes_arena/offline/domain/entities/player_model.dart';
import 'package:pes_arena/main.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBTableColumn {
  static const String id = 'id';
  static const String datetime = 'datetime';
  static const String fullname = 'full_name';

  static const String playerId = "player_id";
  static const String playerLevel = 'level';

  static const String leagueId = 'league_id';

  static const String roundId = 'round_id';

  static const String matchId = 'match_id';
  static const String matchStatus = 'status';

  static const String playerMatchId = 'player_match_id';
  static const String playerMatchPlayerScore = 'player_score';

  static const String playerLeagueId = 'player_league_id';
  static const String playerLeagueTotal = 'total_played';
  static const String playerLeagueWins = 'wins';
  static const String playerLeagueDraws = 'draws';
  static const String playerLeagueLosses = 'losses';
  static const String playerLeagueGD = 'goal_different';
  static const String playerLeaguePoints = 'points';
  static const String playerLeagueGoalsFor = 'goals_for';
  static const String playerLeagueGoalsAgainst = 'goals_against';
}

class DatabaseManager {
  final String createTable = 'CREATE TABLE IF NOT EXISTS';
  final String primaryAuto = 'PRIMARY KEY AUTOINCREMENT';
  final String integer = 'INTEGER';

  final String playerTable = "players";
  final String twoPlayerGames = "two_player_games";
  final String twoPlayerRounds = "two_player_rounds";
  final String playerMatchTable = "player_match_table";
  final String playerLeagueTable = "player_league_table";
  final String matchesTable = "matches_table";
  final String roundsTable = "rounds_table";
  final String leaguesTable = "leagues_table";

  static String databaseFileName = 'game_note_database.db';
  late Future<Database> database;
  Future<void> open() async {
    var path = join(await getDatabasesPath(), databaseFileName);
    dataFile = path;
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      path,
      // onCreate: (db, version) {
      //   return db.execute(
      //       'CREATE TABLE IF NOT EXISTS $playerTable(id INTEGER PRIMARY KEY AUTOINCREMENT, fullname TEXT, level TEXT)');
      // },
      version: 1,
    );
    createTables();
  }

  close() async {
    await (await database).close();
  }

  Future<void> createTables() async {
    final db = await database;
    db.execute(
        '$createTable $playerTable(${DBTableColumn.playerId} $integer $primaryAuto, ${DBTableColumn.fullname} TEXT, ${DBTableColumn.playerLevel} TEXT)');
    db.execute(
        '$createTable $twoPlayerGames(${DBTableColumn.id} $integer $primaryAuto, player1 $integer, player2 $integer, score1 $integer, score2 $integer, photoUrl TEXT)');
    db.execute(
        '$createTable $twoPlayerRounds(${DBTableColumn.id} $integer $primaryAuto, name TEXT, player1 $integer, player2 $integer, games TEXT)');
    db.execute(
        '$createTable $leaguesTable(${DBTableColumn.leagueId} $integer $primaryAuto, ${DBTableColumn.fullname} TEXT, ${DBTableColumn.datetime} TEXT)');
    db.execute(
        '$createTable $roundsTable(${DBTableColumn.roundId} $integer $primaryAuto, ${DBTableColumn.leagueId} $integer)');
    db.execute(
        '$createTable $matchesTable(${DBTableColumn.matchId} $integer $primaryAuto, ${DBTableColumn.roundId} $integer, ${DBTableColumn.datetime} TEXT, ${DBTableColumn.matchStatus} $integer)');
    db.execute(
        '$createTable $playerMatchTable(${DBTableColumn.playerMatchId} $integer $primaryAuto, ${DBTableColumn.playerId} $integer, ${DBTableColumn.matchId} $integer, ${DBTableColumn.playerMatchPlayerScore} $integer)');
    db.execute(
        '$createTable $playerLeagueTable(${DBTableColumn.playerLeagueId} $integer $primaryAuto, ${DBTableColumn.playerId} $integer, ${DBTableColumn.leagueId} $integer, ${DBTableColumn.playerLeagueTotal} $integer, ${DBTableColumn.playerLeagueWins} $integer, ${DBTableColumn.playerLeagueDraws} $integer, ${DBTableColumn.playerLeagueLosses} $integer, ${DBTableColumn.playerLeagueGD} $integer, ${DBTableColumn.playerLeaguePoints} $integer)');
  }

  Future<void> insertPlayer(PlayerModel player) async {
    final db = await database;
    await db.insert(
      playerTable,
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PlayerModel>> players() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(playerTable);
    return List.generate(maps.length, (i) {
      return PlayerModel(
        id: maps[i][DBTableColumn.playerId],
        fullname: maps[i][DBTableColumn.fullname],
        level: maps[i][DBTableColumn.playerLevel],
      );
    });
  }

  Future<PlayerModel?> player(int? id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(playerTable, where: "${DBTableColumn.playerId} = $id");
    return maps.isEmpty
        ? null
        : PlayerModel(
            fullname: maps.first[DBTableColumn.fullname],
            id: maps.first[DBTableColumn.playerId],
            level: maps.first[DBTableColumn.playerLevel],
          );
  }

  Future<void> updatePlayer(PlayerModel player) async {
    final db = await database;
    await db.update(
      playerTable,
      player.toMap(),
      where: '${DBTableColumn.playerId} = ?',
      whereArgs: [player.id],
    );
  }

  Future<int> deletePlayer(PlayerModel player) async {
    final db = await database;
    return await db.delete(
      playerTable,
      where: '${DBTableColumn.playerId} = ?',
      whereArgs: [player.id],
    );
  }
}
