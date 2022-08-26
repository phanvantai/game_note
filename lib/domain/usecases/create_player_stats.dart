import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/core/usecase/usecase.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';
import 'package:game_note/domain/repositories/player_stats_repository.dart';

class CreatePlayerStats
    implements UseCase<PlayerStatsModel, CreatePlayerStatsParams> {
  final PlayerStatsRepository repository;

  CreatePlayerStats(this.repository);
  @override
  Future<Either<Failure, PlayerStatsModel>> call(
      CreatePlayerStatsParams params) {
    return repository.createPlayerStats(params.model);
  }
}

class CreatePlayerStatsParams extends Equatable {
  final PlayerStatsModel model;

  const CreatePlayerStatsParams(this.model);
  @override
  List<Object?> get props => [model];
}
