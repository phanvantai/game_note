import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';
import 'package:game_note/domain/repositories/player_stats_repository.dart';

class GetPlayerStats
    implements UseCase<List<PlayerStatsModel>, GetPlayerStatsParams> {
  final PlayerStatsRepository repository;

  GetPlayerStats(this.repository);
  @override
  Future<Either<Failure, List<PlayerStatsModel>>> call(
      GetPlayerStatsParams params) {
    return repository.getPlayerStats(params.leagueId);
  }
}

class GetPlayerStatsParams extends Equatable {
  final int leagueId;

  const GetPlayerStatsParams(this.leagueId);
  @override
  List<Object?> get props => [leagueId];
}
