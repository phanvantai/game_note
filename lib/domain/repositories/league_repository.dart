import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/core/error/failure.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';

abstract class LeagueRepository {
  Future<Either<Failure, LeagueModel>> createLeague(CreateLeagueParams params);
  Future<Either<Failure, List<LeagueModel>>> getLeagues(
      GetLeaguesParams params);
  Future<Either<Failure, LeagueModel>> getLeague(GetLeagueParams params);
  Future<Either<Failure, LeagueModel>> setPlayersForLeague(
      SetPlayersForLeagueParams params);
  Future<Either<Failure, LeagueModel>> createRounds(CreateRoundsParams params);
  Future<Either<Failure, LeagueModel>> updateMatch(UpdateMatchParams params);
}

class CreateLeagueParams extends Equatable {
  final String name;

  const CreateLeagueParams(this.name);

  @override
  List<Object?> get props => [name];
}

class GetLeaguesParams extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetLeagueParams extends Equatable {
  final int id;

  const GetLeagueParams(this.id);
  @override
  List<Object?> get props => [id];
}

class CreateRoundsParams extends Equatable {
  @override
  List<Object?> get props => [];
}

class SetPlayersForLeagueParams extends Equatable {
  final List<PlayerModel> players;

  const SetPlayersForLeagueParams(this.players);

  @override
  List<Object?> get props => [players];
}

class UpdateMatchParams extends Equatable {
  final MatchModel matchModel;
  final int homeScore;
  final int awayScore;

  const UpdateMatchParams({
    required this.matchModel,
    required this.homeScore,
    required this.awayScore,
  });
  @override
  List<Object?> get props => [matchModel, homeScore, awayScore];
}
