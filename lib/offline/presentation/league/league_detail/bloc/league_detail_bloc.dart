import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/offline/domain/entities/player_model.dart';
import 'package:game_note/offline/domain/repositories/league_repository.dart';
import 'package:game_note/offline/domain/usecases/create_rounds.dart';
import 'package:game_note/offline/domain/usecases/get_league.dart';
import 'package:game_note/offline/domain/usecases/set_players_for_league.dart';
import 'package:game_note/offline/domain/usecases/update_match.dart';

import '../../../../domain/entities/league_model.dart';
import '../../../../domain/entities/match_model.dart';

part 'league_detail_event.dart';
part 'league_detail_state.dart';

class LeagueDetailBloc extends Bloc<LeagueDetailEvent, LeagueDetailState> {
  final GetLeague getLeague;
  final SetPlayersForLeague setPlayersForLeague;
  final CreateRounds createRounds;
  final UpdateMatch updateMatch;
  LeagueDetailBloc({
    required this.getLeague,
    required this.setPlayersForLeague,
    required this.createRounds,
    required this.updateMatch,
  }) : super(const LeagueDetailState()) {
    on<LoadLeagueEvent>(_loadLeague);
    on<AddPlayersStarted>(_startAddPlayers);
    on<AddPlayersToLeague>(_addPlayers);
    on<ConfirmPlayersInLeague>(_confirmPlayers);
    on<AddNewRounds>(_addNewRounds);
    on<UpdateMatchEvent>(_updateMatch);
  }

  _loadLeague(LoadLeagueEvent event, Emitter<LeagueDetailState> emit) async {
    emit(const LeagueDetailState());
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
    emit(state.copyWith(status: LeagueDetailStatus.updating));
    var result = await setPlayersForLeague
        .call(SetPlayersForLeagueParams(state.players));
    result.fold(
      (l) => null,
      (r) => emit(state.copyWith(status: LeagueDetailStatus.loaded, model: r)),
    );
  }

  _addNewRounds(AddNewRounds event, Emitter<LeagueDetailState> emit) async {
    // create rounds
    emit(state.copyWith(status: LeagueDetailStatus.updating));
    var result = await createRounds.call(CreateRoundsParams());
    result.fold(
      (l) => null,
      (r) => emit(state.copyWith(status: LeagueDetailStatus.loaded, model: r)),
    );
  }

  _updateMatch(UpdateMatchEvent event, Emitter<LeagueDetailState> emit) async {
    emit(state.copyWith(status: LeagueDetailStatus.updating));
    var result = await updateMatch.call(UpdateMatchParams(
      matchModel: event.matchModel,
      homeScore: event.homeScore,
      awayScore: event.awayScore,
    ));
    result.fold(
      (l) => null,
      (r) => emit(state.copyWith(status: LeagueDetailStatus.loaded, model: r)),
    );
  }
}
