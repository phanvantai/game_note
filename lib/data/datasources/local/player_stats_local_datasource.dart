import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/core/database/player_stats_manager.dart';
import 'package:game_note/core/error/exception.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';

abstract class PlayerStatsLocalDatasource {
  Future<PlayerStatsModel> createPlayerStats(PlayerStatsModel model);
  Future<List<PlayerStatsModel>> getPlayerStats(int id);
  Future<PlayerStatsModel> updatePlayerStats(PlayerStatsModel model);
}

class PlayerStatsLocalDatasourceImpl implements PlayerStatsLocalDatasource {
  final DatabaseManager databaseManager;

  PlayerStatsLocalDatasourceImpl(this.databaseManager);
  @override
  Future<PlayerStatsModel> createPlayerStats(PlayerStatsModel model) async {
    try {
      var id = await databaseManager.createPlayerStats(model);
      return model.copyWith(id: id);
    } catch (e) {
      throw DatabaseException();
    }
  }

  @override
  Future<List<PlayerStatsModel>> getPlayerStats(int id) async {
    try {
      return databaseManager.getPlayerStats(id);
    } catch (e) {
      throw DatabaseException();
    }
  }

  @override
  Future<PlayerStatsModel> updatePlayerStats(PlayerStatsModel model) {
    // TODO: implement updatePlayerStats
    throw UnimplementedError();
  }
}
