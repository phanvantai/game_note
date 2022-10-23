import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';

abstract class LeagueDetailEvent extends Equatable {
  const LeagueDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadLeagueEvent extends LeagueDetailEvent {
  final int leagueId;

  const LoadLeagueEvent(this.leagueId);

  @override
  List<Object?> get props => [leagueId];
}

class AddPlayersStarted extends LeagueDetailEvent {}

class AddPlayersToLeague extends LeagueDetailEvent {
  final List<PlayerModel> players;

  const AddPlayersToLeague(this.players);

  @override
  List<Object?> get props => [players];
}

class ConfirmPlayersInLeague extends LeagueDetailEvent {}

class AddNewRounds extends LeagueDetailEvent {}

class UpdateMatchEvent extends LeagueDetailEvent {
  final MatchModel matchModel;
  final int homeScore;
  final int awayScore;

  const UpdateMatchEvent({
    required this.matchModel,
    required this.homeScore,
    required this.awayScore,
  });

  @override
  List<Object?> get props => [matchModel, homeScore, awayScore];
}
