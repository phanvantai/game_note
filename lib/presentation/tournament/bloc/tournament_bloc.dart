import 'package:bloc/bloc.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/usecases/create_league.dart';
import 'package:game_note/presentation/models/tournament_helper.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  final CreateLeague createLeague;
  TournamentBloc(this.createLeague) : super(const TournamentState()) {
    on<LoadListLeagueEvent>(_loadListTournament);
    on<AddNewLeagueEvent>(_createNewLeague);
    on<SelectLeagueEvent>(_selectLeague);
    on<CloseLeagueDetailEvent>(_closeLeagueDetail);
    on<AddPlayersToTournament>(_addPlayersToTournament);
    on<AddNewRoundEvent>(_addNewRound);
  }

  _loadListTournament(
      LoadListLeagueEvent event, Emitter<TournamentState> emit) async {
    emit(state.copyWith(status: TournamentStatus.list));
  }

  _createNewLeague(
      AddNewLeagueEvent event, Emitter<TournamentState> emit) async {
    emit(state.copyWith(status: TournamentStatus.loading));
    // create league
    var now = DateTime.now();
    var name = '${now.year}-${now.month}-${now.day} ${event.name}';
    var result = await createLeague.call(CreateLeagueParam(name));
    result.fold(
      (l) => emit(state.copyWith(status: TournamentStatus.error)),
      (r) =>
          emit(state.copyWith(status: TournamentStatus.league, leagueModel: r)),
    );
  }

  _selectLeague(SelectLeagueEvent event, Emitter<TournamentState> emit) {
    emit(state.copyWith(
        status: TournamentStatus.league, leagueModel: event.leagueModel));
  }

  _closeLeagueDetail(
      CloseLeagueDetailEvent event, Emitter<TournamentState> emit) {
    emit(state.copyWith(status: TournamentStatus.list));
  }

  _addPlayersToTournament(
      AddPlayersToTournament event, Emitter<TournamentState> emit) async {
    emit(state.copyWith(status: TournamentStatus.list));
    emit(state.copyWith(
      status: TournamentStatus.league,
      players: event.players,
      matches: MatchModelX.from(TournamentHelper.createMatches(
          event.players, PlayerModel.virtualPlayer)),
    ));
  }

  _addNewRound(AddNewRoundEvent event, Emitter<TournamentState> emit) async {
    var abcdef = MatchModelX.from(TournamentHelper.createMatches(
        state.players, PlayerModel.virtualPlayer));
    state.matches.addAll(abcdef);
    emit(state.copyWith(status: TournamentStatus.league));
  }
}
