import 'package:pes_arena/offline/data/database/database_manager.dart';
import 'package:pes_arena/offline/data/database/league_manager.dart';
import 'package:pes_arena/core/common/exception.dart';
import 'package:pes_arena/offline/domain/entities/league_model.dart';
import 'package:pes_arena/offline/domain/entities/match_model.dart';
import 'package:pes_arena/offline/domain/entities/player_model.dart';
import 'package:pes_arena/injection_container.dart';

import '../models/league_manager.dart';

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
  Future<int> deleteLeague(int leagueId);
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

  @override
  Future<int> deleteLeague(int leagueId) {
    try {
      final dm = getIt<DatabaseManager>();
      return dm.deleteLeague(leagueId);
    } catch (e) {
      rethrow;
    }
  }
}
