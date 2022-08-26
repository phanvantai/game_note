import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';
import 'package:game_note/domain/repositories/player_stats_repository.dart';

class UpdatePlayerStats
    implements UseCase<PlayerStatsModel, UpdatePlayerStatsParams> {
  final PlayerStatsRepository repository;

  UpdatePlayerStats(this.repository);
  @override
  Future<Either<Failure, PlayerStatsModel>> call(
      UpdatePlayerStatsParams params) {
    return repository.updatePlayerStats(params.model);
  }
}

class UpdatePlayerStatsParams extends Equatable {
  final PlayerStatsModel model;

  const UpdatePlayerStatsParams(this.model);
  @override
  List<Object?> get props => [model];
}
