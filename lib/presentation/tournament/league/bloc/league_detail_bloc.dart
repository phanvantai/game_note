import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';
import 'package:game_note/domain/usecases/create_player_stats.dart';
import 'package:game_note/domain/usecases/get_league.dart';
import 'package:game_note/domain/usecases/get_player_stats.dart';
import 'package:game_note/domain/usecases/update_player_stats.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_event.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_state.dart';

class LeagueDetailBloc extends Bloc<LeagueDetailEvent, LeagueDetailState> {
  final GetLeague getLeague;
  final CreatePlayerStats createPlayerStats;
  final GetPlayerStats getPlayerStats;
  final UpdatePlayerStats updatePlayerStats;
  LeagueDetailBloc({
    required this.getLeague,
    required this.createPlayerStats,
    required this.getPlayerStats,
    required this.updatePlayerStats,
  }) : super(const LeagueDetailState()) {
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
    emit(state.copyWith(status: LeagueDetailStatus.updating));
    // create players stats
    List<PlayerStatsModel> playersStats = [];
    for (var player in state.players) {
      var abc = await createPlayerStats.call(CreatePlayerStatsParams(
          PlayerStatsModel(playerModel: player, leagueId: state.model!.id!)));
      abc.fold((l) => null, (r) => playersStats.add(r));
    }
    var league = state.model!.copyWith(players: playersStats);
    emit(state.copyWith(status: LeagueDetailStatus.loaded, model: league));
  }
}
