import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/usecases/get_league.dart';
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
  }

  _loadLeague(LoadLeagueEvent event, Emitter<LeagueDetailState> emit) async {
    var result = await getLeague.call(GetLeagueParams(event.leagueId));
    result.fold(
      (l) => emit(state.copyWith(status: LeagueDetailStatus.error)),
      (r) {
        if (r.players.isEmpty) {
          emit(state.copyWith(status: LeagueDetailStatus.empty, model: r));
        } else {
          emit(state.copyWith(status: LeagueDetailStatus.loaded, model: r));
        }
      },
    );
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
    // create round/match/player stats
    // create player stats
    print('create player stats');
    emit(state.copyWith(status: LeagueDetailStatus.loaded));
  }
}
