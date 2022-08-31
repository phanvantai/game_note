import 'package:game_note/core/error/exception.dart';
import 'package:game_note/data/datasources/local/round_local_datasource.dart';
import 'package:game_note/domain/entities/round_model.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:game_note/domain/repositories/round_repository.dart';

class RoundRepositoryImpl implements RoundRepository {
  final RoundLocalDatasource localDatasource;

  RoundRepositoryImpl(this.localDatasource);
  @override
  Future<Either<Failure, RoundModel>> createRound(RoundModel model) async {
    try {
      return Right(await localDatasource.createRound(model));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoundModel>>> getRounds(int leagueId) async {
    try {
      return Right(await localDatasource.getRounds(leagueId));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }
}
