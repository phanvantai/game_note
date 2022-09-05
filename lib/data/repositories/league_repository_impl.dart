import 'package:game_note/core/error/exception.dart';
import 'package:game_note/data/datasources/local/league_local_datasource.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/repositories/league_repository.dart';

class LeagueRepositoryImpl implements LeagueRepository {
  final LeagueLocalDatasource localDatasource;

  LeagueRepositoryImpl(this.localDatasource);
  @override
  Future<Either<Failure, LeagueModel>> createLeague(String name) async {
    try {
      return Right(await localDatasource.createLeague(name));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LeagueModel>> getLeague(int id) async {
    try {
      return Right(await localDatasource.getLeague(id));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LeagueModel>>> getLeagues() async {
    try {
      return Right(await localDatasource.getLeagues());
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LeagueModel>> setPlayersForLeague(
      List<PlayerModel> players) async {
    try {
      return Right(await localDatasource.setPlayersForLeague(players));
    } on DatabaseException catch (e) {
      return Left(LocalFailure(e.toString()));
    }
  }
}
