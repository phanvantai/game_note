import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';

class TournamentEvent extends Equatable {
  const TournamentEvent();
  @override
  List<Object?> get props => [];
}

class LoadListTournamentEvent extends TournamentEvent {}

class AddNewTournamentEvent extends TournamentEvent {
  final String name;

  const AddNewTournamentEvent(this.name);
  @override
  List<Object?> get props => [name];
}

class AddNewRoundEvent extends TournamentEvent {}

class CloseToLastStateEvent extends TournamentEvent {}

class AddPlayersToTournament extends TournamentEvent {
  final List<PlayerModel> players;

  const AddPlayersToTournament({required this.players});

  @override
  List<Object?> get props => [players];
}

class UpdateMatchEvent extends TournamentEvent {
  final MatchModel matchModel;
  final int home;
  final int away;

  const UpdateMatchEvent(
      {required this.matchModel, required this.home, required this.away});

  @override
  List<Object?> get props => [matchModel, home, away];
}
