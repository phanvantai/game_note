import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/usecases/get_league.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/data/models/league_manager.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_event.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_state.dart';

class LeagueDetailBloc extends Bloc<LeagueDetailEvent, LeagueDetailState> {
  final GetLeague getLeague;
  LeagueDetailBloc({required this.getLeague})
      : super(const LeagueDetailState()) {
    on<LoadLeagueEvent>(_loadLeague);
    on<AddPlayersStarted>(_startAddPlayers);
    on<AddPlayersToLeague>(_addPlayers);
    on<ConfirmPlayersInLeague>(_confirmPlayers);
    on<AddNewRounds>(_addNewRounds);
    on<UpdateMatch>(_updateMatch);
  }

  _loadLeague(LoadLeagueEvent event, Emitter<LeagueDetailState> emit) async {
    emit(state.copyWith(status: LeagueDetailStatus.loading));
    var result = await getLeague.call(GetLeagueParams(event.leagueId));
    result.fold((l) => null, (r) {
      if (r.players.isEmpty) {
        emit(state.copyWith(status: LeagueDetailStatus.empty, model: r));
      } else {
        emit(state.copyWith(
          status: LeagueDetailStatus.loaded,
          model: r,
          players: r.players.map((e) => e.playerModel).toList(),
        ));
      }
    });
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
    emit(state.copyWith(
        status: LeagueDetailStatus.loaded, model: leagueManager.league));
  }

  _updateMatch(UpdateMatch event, Emitter<LeagueDetailState> emit) async {
    emit(state.copyWith(status: LeagueDetailStatus.updating));
    LeagueManager leagueManager = getIt();
    await leagueManager.updateMatch(
        event.matchModel, event.homeScore, event.awayScore);
    emit(state.copyWith(
        status: LeagueDetailStatus.loaded, model: leagueManager.league));
  }
}
