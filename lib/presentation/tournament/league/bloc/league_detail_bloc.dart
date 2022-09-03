import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/models/league_manager.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_event.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_state.dart';

class LeagueDetailBloc extends Bloc<LeagueDetailEvent, LeagueDetailState> {
  LeagueDetailBloc() : super(const LeagueDetailState()) {
    on<LoadLeagueEvent>(_loadLeague);
    on<AddPlayersStarted>(_startAddPlayers);
    on<AddPlayersToLeague>(_addPlayers);
    on<ConfirmPlayersInLeague>(_confirmPlayers);
    on<AddNewRounds>(_addNewRounds);
  }

  _loadLeague(LoadLeagueEvent event, Emitter<LeagueDetailState> emit) async {
    LeagueManager leagueManager = getIt();
    await leagueManager.getLeague(event.leagueId);
    if (leagueManager.league.players.isEmpty) {
      emit(state.copyWith(
          status: LeagueDetailStatus.empty, model: leagueManager.league));
    } else {
      emit(state.copyWith(
        status: LeagueDetailStatus.loaded,
        model: leagueManager.league,
        players:
            leagueManager.league.players.map((e) => e.playerModel).toList(),
      ));
    }
  }

  _startAddPlayers(AddPlayersStarted event, Emitter<LeagueDetailState> emit) {
    emit(state.copyWith(status: LeagueDetailStatus.addingPlayer));
  }

  _addPlayers(AddPlayersToLeague event, Emitter<LeagueDetailState> emit) {
    List<PlayerModel> players = [];
    players.addAll(event.players);
    emit(state.copyWith(players: players, enable: players.length > 2));
  }

  _confirmPlayers(
      ConfirmPlayersInLeague event, Emitter<LeagueDetailState> emit) async {
    // create player stats
    emit(state.copyWith(status: LeagueDetailStatus.updating));
    // create players stats
    LeagueManager leagueManager = getIt();
    await leagueManager.setPlayers(state.players);
    await leagueManager.addPlayersToLeague();
    emit(state.copyWith(
        status: LeagueDetailStatus.loaded, model: leagueManager.league));
  }

  _addNewRounds(AddNewRounds event, Emitter<LeagueDetailState> emit) async {
    // create rounds
    emit(state.copyWith(status: LeagueDetailStatus.updating));
    LeagueManager leagueManager = getIt();
    await leagueManager.createRounds();
  }
}
