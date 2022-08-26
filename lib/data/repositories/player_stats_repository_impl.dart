import 'package:game_note/core/error/exception.dart';
import 'package:game_note/data/datasources/local/player_stats_local_datasource.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:game_note/domain/repositories/player_stats_repository.dart';

class PlayerStatsRepositoryImpl implements PlayerStatsRepository {
  final PlayerStatsLocalDatasource localDatasource;

  PlayerStatsRepositoryImpl(this.localDatasource);
  @override
  Future<Either<Failure, PlayerStatsModel>> createPlayerStats(
      PlayerStatsModel model) async {
    try {
      return Right(await localDatasource.createPlayerStats(model));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlayerStatsModel>>> getPlayerStats(int leagueId) {
    // TODO: implement getPlayerStats
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, PlayerStatsModel>> updatePlayerStats(
      PlayerStatsModel model) {
    // TODO: implement updatePlayerStats
    throw UnimplementedError();
  }
}
