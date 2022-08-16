import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  TournamentBloc() : super(const TournamentState()) {
    on<LoadListTournamentEvent>(_loadListTournament);
    on<AddNewTournamentEvent>(_addNewTournament);
    on<CloseToLastStateEvent>(_closeToLastState);
    on<AddPlayersToTournament>(_addPlayersToTournament);
  }

  _loadListTournament(
      LoadListTournamentEvent event, Emitter<TournamentState> emit) async {
    emit(state.copyWith(status: TournamentStatus.list, lastState: state));
  }

  _addNewTournament(
      AddNewTournamentEvent event, Emitter<TournamentState> emit) {
    emit(state.copyWith(status: TournamentStatus.addPlayer, lastState: state));
  }

  _closeToLastState(
      CloseToLastStateEvent event, Emitter<TournamentState> emit) {
    emit(state.lastState ?? state);
  }

  _addPlayersToTournament(
      AddPlayersToTournament event, Emitter<TournamentState> emit) async {
    emit(state.copyWith(status: TournamentStatus.list, lastState: state));
    emit(state.copyWith(
      status: TournamentStatus.tournament,
      players: event.players,
      matches: [],
      lastState: state,
    ));
  }
}
