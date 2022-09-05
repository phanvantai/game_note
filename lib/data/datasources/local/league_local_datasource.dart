import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/core/database/league_manager.dart';
import 'package:game_note/core/error/exception.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/data/models/league_manager.dart';

abstract class LeagueLocalDatasource {
  // datasource
  // error throw database exception
  Future<LeagueModel> createLeague(String name);
  Future<LeagueModel> getLeague(int id);
  Future<List<LeagueModel>> getLeagues();
  Future<LeagueModel> setPlayersForLeague(List<PlayerModel> players);
  Future<LeagueModel> createRounds();
  Future<LeagueModel> updateMatch(
      MatchModel matchModel, int homeScore, int awayScore);
}

class LeagueLocalDatasourceImpl implements LeagueLocalDatasource {
  final DatabaseManager databaseManager;

  LeagueLocalDatasourceImpl(this.databaseManager);

  @override
  Future<LeagueModel> createLeague(String name) async {
    try {
      var league = LeagueModel(name: name, dateTime: DateTime.now());
      var id = await databaseManager.createLeague(league);
      var result = await databaseManager.getLeague(id);
      if (result != null) {
        return result;
      }
      throw DatabaseException();
    } catch (e) {
      throw DatabaseException();
    }
  }

  @override
  Future<List<LeagueModel>> getLeagues() async {
    try {
      return await databaseManager.getLeagues();
    } catch (e) {
      throw DatabaseException();
    }
  }

  @override
  Future<LeagueModel> getLeague(int id) async {
    try {
      LeagueManager leagueManager = getIt();
      await leagueManager.getLeague(id);
      return leagueManager.league;
    } catch (e) {
      throw DatabaseException();
    }
  }

  @override
  Future<LeagueModel> setPlayersForLeague(List<PlayerModel> players) async {
    try {
      LeagueManager leagueManager = getIt();
      await leagueManager.setPlayers(players);
      await leagueManager.addPlayersToLeague();
      return leagueManager.league;
    } catch (e) {
      throw DatabaseException();
    }
  }

  @override
  Future<LeagueModel> createRounds() async {
    try {
      LeagueManager leagueManager = getIt();
      await leagueManager.createRounds();
      return leagueManager.league;
    } catch (e) {
      throw DatabaseException();
    }
  }

  @override
  Future<LeagueModel> updateMatch(
      MatchModel matchModel, int homeScore, int awayScore) async {
    try {
      LeagueManager leagueManager = getIt();
      await leagueManager.updateMatch(matchModel, homeScore, awayScore);
      return leagueManager.league;
    } catch (e) {
      throw DatabaseException();
    }
  }
}
