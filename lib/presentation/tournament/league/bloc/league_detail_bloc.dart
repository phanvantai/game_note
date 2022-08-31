import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';
import 'package:game_note/domain/entities/round_model.dart';
import 'package:game_note/domain/usecases/create_player_stats.dart';
import 'package:game_note/domain/usecases/create_round.dart';
import 'package:game_note/domain/usecases/get_league.dart';
import 'package:game_note/domain/usecases/get_player_stats.dart';
import 'package:game_note/domain/usecases/get_rounds.dart';
import 'package:game_note/domain/usecases/update_player_stats.dart';
import 'package:game_note/presentation/models/tournament_helper.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_event.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_state.dart';

class LeagueDetailBloc extends Bloc<LeagueDetailEvent, LeagueDetailState> {
  final GetLeague getLeague;

  final CreatePlayerStats createPlayerStats;
  final GetPlayerStats getPlayerStats;
  final UpdatePlayerStats updatePlayerStats;

  final CreateRound createRound;
  final GetRounds getRounds;
  LeagueDetailBloc({
    required this.getLeague,
    required this.createPlayerStats,
    required this.getPlayerStats,
    required this.updatePlayerStats,
    required this.createRound,
    required this.getRounds,
  }) : super(const LeagueDetailState()) {
    on<LoadLeagueEvent>(_loadLeague);
    on<AddPlayersStarted>(_startAddPlayers);
    on<AddPlayersToLeague>(_addPlayers);
    on<ConfirmPlayersInLeague>(_confirmPlayers);
    on<AddNewRounds>(_addNewRounds);
  }

  _loadLeague(LoadLeagueEvent event, Emitter<LeagueDetailState> emit) async {
    var result = await getLeague.call(GetLeagueParams(event.leagueId));
    result.fold(
      (l) => emit(state.copyWith(status: LeagueDetailStatus.error)),
      (r) {
        print(r);
        if (r.players.isEmpty) {
          emit(state.copyWith(status: LeagueDetailStatus.empty, model: r));
        } else {
          emit(state.copyWith(
            status: LeagueDetailStatus.loaded,
            model: r,
            players: r.players.map((e) => e.playerModel).toList(),
          ));
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
    // create player stats
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

  _addNewRounds(AddNewRounds event, Emitter<LeagueDetailState> emit) async {
    // create rounds
    emit(state.copyWith(status: LeagueDetailStatus.updating));
    var listMaps = TournamentHelper.createRounds(
      state.players,
      PlayerModel.virtualPlayer,
    );
    List<RoundModel> rounds = [];
    for (var element in listMaps) {
      // create round
      var resultRound = await createRound
          .call(CreateRoundParams(RoundModel(leagueId: state.model!.id!)));
      if (resultRound.isLeft()) {
        continue;
      }
      resultRound.fold((l) => null, (r) {
        // create matches
        // create result for match
        print(r);
        rounds.add(r);
      });
      List<MatchModel> matches = [];
    }
  }
}
