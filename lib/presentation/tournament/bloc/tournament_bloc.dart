import 'package:bloc/bloc.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/entities/result_model.dart';
import 'package:game_note/domain/usecases/create_league.dart';
import 'package:game_note/presentation/models/tournament_helper.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  final CreateLeague createLeague;
  TournamentBloc(this.createLeague) : super(const TournamentState()) {
    on<LoadListTournamentEvent>(_loadListTournament);
    on<AddNewTournamentEvent>(_addNewTournament);
    on<CloseToLastStateEvent>(_closeToLastState);
    on<AddPlayersToTournament>(_addPlayersToTournament);
    on<AddNewRoundEvent>(_addNewRound);
    on<UpdateMatchEvent>(_updateMatch);
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
    var abcdef = MatchModelX.from(TournamentHelper.createMatches(
        state.players, PlayerModel.virtualPlayer));
    state.matches.addAll(abcdef);
    emit(state.copyWith(status: TournamentStatus.tournament));
  }

  _updateMatch(UpdateMatchEvent event, Emitter<TournamentState> emit) async {
    emit(state.copyWith(status: TournamentStatus.updatingTournament));
    var index = state.matches.indexOf(event.matchModel);
    state.matches[index] = MatchModel(
      home: ResultModel(
        playerModel: event.matchModel.home.playerModel,
        score: event.home,
      ),
      away: ResultModel(
        playerModel: event.matchModel.away.playerModel,
        score: event.away,
      ),
      status: true,
    );
    emit(state.copyWith(
      status: TournamentStatus.tournament,
      matches: state.matches,
    ));
  }
}
