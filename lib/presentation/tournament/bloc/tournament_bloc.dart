import 'package:bloc/bloc.dart';
import 'package:game_note/domain/repositories/league_repository.dart';
import 'package:game_note/domain/usecases/create_league.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  final CreateLeague createLeague;
  TournamentBloc(this.createLeague) : super(const TournamentState()) {
    on<LoadListLeagueEvent>(_loadListTournament);
    on<AddNewLeagueEvent>(_createNewLeague);
    on<SelectLeagueEvent>(_selectLeague);
    on<CloseLeagueDetailEvent>(_closeLeagueDetail);
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
    var result = await createLeague.call(CreateLeagueParams(name));
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
}
