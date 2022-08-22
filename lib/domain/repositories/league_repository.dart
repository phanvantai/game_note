import 'package:dartz/dartz.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/domain/entities/league_model.dart';

abstract class LeagueRepository {
  Future<Either<Failure, LeagueModel>> createLeague(String name);
  Future<Either<Failure, List<LeagueModel>>> getLeagues();
  Future<Either<Failure, LeagueModel>> getLeague(int id);
}
