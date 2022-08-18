import 'package:bloc/bloc.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/presentation/models/tournament_helper.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  TournamentBloc() : super(const TournamentState()) {
    on<LoadListTournamentEvent>(_loadListTournament);
    on<AddNewTournamentEvent>(_addNewTournament);
    on<CloseToLastStateEvent>(_closeToLastState);
    on<AddPlayersToTournament>(_addPlayersToTournament);
    on<AddNewRoundEvent>(_addNewRound);
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
      matches: MatchModelX.from(TournamentHelper.createMatches(
          event.players, PlayerModel.virtualPlayer)),
      lastState: state,
    ));
  }

  _addNewRound(AddNewRoundEvent event, Emitter<TournamentState> emit) async {
    emit(state.copyWith(status: TournamentStatus.updatingTournament));
    // TODO: -
  }
}
