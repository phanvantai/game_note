import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/core/database/league_manager.dart';
import 'package:game_note/core/error/exception.dart';
import 'package:game_note/domain/entities/league_model.dart';

abstract class LeagueLocalDatasource {
  // datasource
  // error throw database exception
  Future<LeagueModel> createLeague(String name);
  Future<LeagueModel> getLeague(int id);
  Future<List<LeagueModel>> getLeagues();
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
      var league = await databaseManager.getLeague(id);
      if (league != null) {
        return league;
      }
      throw DatabaseException();
    } catch (e) {
      throw DatabaseException();
    }
  }
}
