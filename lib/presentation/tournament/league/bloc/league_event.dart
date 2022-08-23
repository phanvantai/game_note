import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/player_model.dart';

abstract class LeagueEvent extends Equatable {
  const LeagueEvent();
  @override
  List<Object?> get props => [];
}

class LoadLeagueEvent extends LeagueEvent {
  final String leagueId;

  const LoadLeagueEvent(this.leagueId);

  @override
  List<Object?> get props => [leagueId];
}

class AddPlayersToLeague extends LeagueEvent {
  final List<PlayerModel> players;

  const AddPlayersToLeague(this.players);

  @override
  List<Object?> get props => [players];
}

class AddNewRoundToLeague extends LeagueEvent {}
