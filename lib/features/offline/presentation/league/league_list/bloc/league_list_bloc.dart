import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/features/offline/domain/repositories/league_repository.dart';
import 'package:game_note/features/offline/domain/usecases/delete_league.dart';
import 'package:game_note/features/offline/domain/usecases/get_leagues.dart';

import '../../../../../../features/offline/domain/entities/league_model.dart';

part 'league_list_event.dart';
part 'league_list_state.dart';

class LeagueListBloc extends Bloc<LeagueListEvent, LeagueListState> {
  final GetLeagues getLeagues;
  final DeleteLeague deleteLeague;
  LeagueListBloc({
    required this.getLeagues,
    required this.deleteLeague,
  }) : super(const LeagueListState()) {
    on<LeagueListStarted>(_onStarted);
    on<DeleteLeagueEvent>(_onDeleteLeague);
  }

  _onStarted(LeagueListStarted event, Emitter<LeagueListState> emit) async {
    emit(state.copyWith(status: LeagueListStatus.loading));
    var result = await getLeagues.call(GetLeaguesParams());
    result.fold(
      (l) => emit(state.copyWith(status: LeagueListStatus.error)),
      (r) => emit(state.copyWith(status: LeagueListStatus.loaded, leagues: r)),
    );
  }

  _onDeleteLeague(
      DeleteLeagueEvent event, Emitter<LeagueListState> emit) async {
    if (event.leagueModel.id == null) {
      return;
    }
    emit(state.copyWith(status: LeagueListStatus.loading));
    final result =
        await deleteLeague.call(GetLeagueParams(event.leagueModel.id!));
    result.fold((l) => null, (r) {
      add(LeagueListStarted());
    });
  }
}
