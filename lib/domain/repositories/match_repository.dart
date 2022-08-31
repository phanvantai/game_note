import 'package:dartz/dartz.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/domain/entities/match_model.dart';

abstract class MatchRepository {
  Future<Either<Failure, MatchModel>> createMatch(MatchModel model);
  Future<Either<Failure, List<MatchModel>>> getMatches(int roundId);
  Future<Either<Failure, MatchModel>> getMatch(int matchId);
}
