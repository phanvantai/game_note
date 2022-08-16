import 'package:equatable/equatable.dart';

class TournamentEvent extends Equatable {
  const TournamentEvent();
  @override
  List<Object?> get props => [];
}

class LoadListTournamentEvent extends TournamentEvent {}

class AddNewTournamentEvent extends TournamentEvent {}

class CloseToLastStateEvent extends TournamentEvent {}
