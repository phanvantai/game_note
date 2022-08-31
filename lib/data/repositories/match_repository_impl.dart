import 'package:game_note/core/error/exception.dart';
import 'package:game_note/data/datasources/local/match_local_datasource.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:game_note/domain/repositories/match_repository.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchLocalDatasource localDatasource;

  MatchRepositoryImpl(this.localDatasource);
  @override
  Future<Either<Failure, MatchModel>> createMatch(MatchModel model) async {
    try {
      return Right(await localDatasource.createMatch(model));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MatchModel>> getMatch(int matchId) {
    // TODO: implement getMatch
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<MatchModel>>> getMatches(int roundId) async {
    try {
      return Right(await localDatasource.getMatches(roundId));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }
}
