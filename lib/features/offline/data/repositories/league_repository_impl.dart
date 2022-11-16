import 'package:game_note/core/error/exception.dart';
import 'package:game_note/features/offline/data/datasources/league_local_datasource.dart';
import 'package:game_note/features/offline/domain/entities/league_model.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:game_note/features/offline/domain/repositories/league_repository.dart';

class LeagueRepositoryImpl implements LeagueRepository {
  final LeagueLocalDatasource localDatasource;

  LeagueRepositoryImpl(this.localDatasource);
  @override
  Future<Either<Failure, LeagueModel>> createLeague(
      CreateLeagueParams params) async {
    try {
      return Right(await localDatasource.createLeague(params.name));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LeagueModel>> updateMatch(
      UpdateMatchParams params) async {
    try {
      return Right(await localDatasource.updateMatch(
          params.matchModel, params.homeScore, params.awayScore));
    } catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LeagueModel>> createRounds(
      CreateRoundsParams params) async {
    try {
      return Right(await localDatasource.createRounds());
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LeagueModel>> getLeague(GetLeagueParams params) async {
    try {
      return Right(await localDatasource.getLeague(params.id));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LeagueModel>>> getLeagues(
      GetLeaguesParams params) async {
    try {
      return Right(await localDatasource.getLeagues());
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LeagueModel>> setPlayersForLeague(
      SetPlayersForLeagueParams params) async {
    try {
      return Right(await localDatasource.setPlayersForLeague(params.players));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }
}
