import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/core/database/round_manager.dart';
import 'package:game_note/core/error/exception.dart';
import 'package:game_note/domain/entities/round_model.dart';

abstract class RoundLocalDatasource {
  Future<RoundModel> createRound(RoundModel model);
  Future<List<RoundModel>> getRounds(int leagueId);
}

class RoundLocalDatasourceImpl implements RoundLocalDatasource {
  final DatabaseManager databaseManager;

  RoundLocalDatasourceImpl(this.databaseManager);
  @override
  Future<RoundModel> createRound(RoundModel model) async {
    try {
      var id = await databaseManager.createRound(model);
      return model.copyWith(id: id);
    } catch (e) {
      throw DatabaseException();
    }
  }

  @override
  Future<List<RoundModel>> getRounds(int leagueId) async {
    // TODO: implement getRounds
    throw UnimplementedError();
  }
}
