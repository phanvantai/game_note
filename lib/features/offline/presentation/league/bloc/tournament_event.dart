part of 'tournament_bloc.dart';

class TournamentEvent extends Equatable {
  const TournamentEvent();
  @override
  List<Object?> get props => [];
}

class LoadListLeagueEvent extends TournamentEvent {}

class AddNewLeagueEvent extends TournamentEvent {
  final String name;

  const AddNewLeagueEvent(this.name);
  @override
  List<Object?> get props => [name];
}

class SelectLeagueEvent extends TournamentEvent {
  final LeagueModel leagueModel;

  const SelectLeagueEvent(this.leagueModel);

  @override
  List<Object?> get props => [leagueModel];
}

class CloseLeagueDetailEvent extends TournamentEvent {}
