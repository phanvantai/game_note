import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/usecases/get_league.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_event.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_state.dart';

class LeagueDetailBloc extends Bloc<LeagueDetailEvent, LeagueDetailState> {
  final GetLeague getLeague;
  LeagueDetailBloc({required this.getLeague})
      : super(const LeagueDetailState()) {
    on<LoadLeagueEvent>(_loadLeague);
  }

  _loadLeague(LoadLeagueEvent event, Emitter<LeagueDetailState> emit) async {
    var result = await getLeague.call(GetLeagueParams(event.leagueId));
    result.fold(
      (l) => emit(state.copyWith(status: LeagueDetailStatus.error)),
      (r) {
        print(r);
        emit(state.copyWith(status: LeagueDetailStatus.loaded, model: r));
      },
    );
  }
}
