import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/domain/entities/round_model.dart';
import 'package:game_note/domain/repositories/round_repository.dart';

class GetRounds implements UseCase<List<RoundModel>, GetRoundsParams> {
  final RoundRepository repository;

  GetRounds(this.repository);
  @override
  Future<Either<Failure, List<RoundModel>>> call(GetRoundsParams params) {
    return repository.getRounds(params.leagueId);
  }
}

class GetRoundsParams extends Equatable {
  final int leagueId;

  const GetRoundsParams(this.leagueId);
  @override
  List<Object?> get props => [leagueId];
}
