import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/repositories/match_repository.dart';

class GetMatches implements UseCase<List<MatchModel>, GetMatchesParams> {
  final MatchRepository repository;

  GetMatches(this.repository);
  @override
  Future<Either<Failure, List<MatchModel>>> call(GetMatchesParams params) {
    return repository.getMatches(params.roundId);
  }
}

class GetMatchesParams extends Equatable {
  final int roundId;

  const GetMatchesParams(this.roundId);
  @override
  List<Object?> get props => [roundId];
}
