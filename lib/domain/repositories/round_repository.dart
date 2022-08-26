import 'package:dartz/dartz.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/domain/entities/round_model.dart';

abstract class RoundRepository {
  Future<Either<Failure, RoundModel>> createRound(RoundModel model);
  Future<Either<Failure, List<RoundModel>>> getRounds(int leagueId);
}
