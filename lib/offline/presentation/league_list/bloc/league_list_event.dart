part of 'league_list_bloc.dart';

class LeagueListEvent extends Equatable {
  const LeagueListEvent();
  @override
  List<Object?> get props => [];
}

class LeagueListStarted extends LeagueListEvent {}

class CreateLeagueEvent extends LeagueListEvent {
  final String name;

  const CreateLeagueEvent(this.name);

  @override
  List<Object?> get props => [name];
}

class DeleteLeagueEvent extends LeagueListEvent {
  final LeagueModel leagueModel;

  const DeleteLeagueEvent(this.leagueModel);

  @override
  List<Object?> get props => [leagueModel];
}
