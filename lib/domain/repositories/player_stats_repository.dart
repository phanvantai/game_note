import 'package:dartz/dartz.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';

abstract class PlayerStatsRepository {
  Future<Either<Failure, PlayerStatsModel>> createPlayerStats(
      PlayerStatsModel model);
  Future<Either<Failure, List<PlayerStatsModel>>> getPlayerStats(int leagueId);
  Future<Either<Failure, PlayerStatsModel>> updatePlayerStats(
      PlayerStatsModel model);
}
