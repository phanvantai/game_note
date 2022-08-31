import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/core/database/match_manager.dart';
import 'package:game_note/core/error/exception.dart';
import 'package:game_note/domain/entities/match_model.dart';

abstract class MatchLocalDatasource {
  Future<MatchModel> createMatch(MatchModel model);
  Future<List<MatchModel>> getMatches(int roundId);
  Future<MatchModel> getMatch(int matchId);
}

class MatchLocalDatasourceImpl implements MatchLocalDatasource {
  final DatabaseManager databaseManager;

  MatchLocalDatasourceImpl(this.databaseManager);
  @override
  Future<MatchModel> createMatch(MatchModel model) async {
    try {
      var id = await databaseManager.createMatch(model);
      return model.copyWith(id: id);
    } catch (e) {
      throw DatabaseException();
    }
  }

  @override
  Future<MatchModel> getMatch(int matchId) {
    // TODO: implement getMatch
    throw UnimplementedError();
  }

  @override
  Future<List<MatchModel>> getMatches(int roundId) {
    try {
      return databaseManager.getMatches(roundId);
    } catch (e) {
      throw DatabaseException();
    }
  }
}
