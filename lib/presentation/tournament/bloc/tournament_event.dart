import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/player_model.dart';

class TournamentEvent extends Equatable {
  const TournamentEvent();
  @override
  List<Object?> get props => [];
}

class LoadListTournamentEvent extends TournamentEvent {}

class AddNewTournamentEvent extends TournamentEvent {}

class AddNewRoundEvent extends TournamentEvent {}

class CloseToLastStateEvent extends TournamentEvent {}

class AddPlayersToTournament extends TournamentEvent {
  final List<PlayerModel> players;

  const AddPlayersToTournament({required this.players});

  @override
  List<Object?> get props => [players];
}
