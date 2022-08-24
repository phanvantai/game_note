import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/domain/entities/player_model.dart';

abstract class LeagueDetailEvent extends Equatable {
  const LeagueDetailEvent();
  @override
  List<Object?> get props => [];
}

class InitilizeLeagueEvent extends LeagueDetailEvent {
  final LeagueModel model;

  const InitilizeLeagueEvent(this.model);

  @override
  List<Object?> get props => [model];
}

class LoadLeagueEvent extends LeagueDetailEvent {
  final String leagueId;

  const LoadLeagueEvent(this.leagueId);

  @override
  List<Object?> get props => [leagueId];
}

class AddPlayersToLeague extends LeagueDetailEvent {
  final List<PlayerModel> players;

  const AddPlayersToLeague(this.players);

  @override
  List<Object?> get props => [players];
}

class AddNewRoundToLeague extends LeagueDetailEvent {}
