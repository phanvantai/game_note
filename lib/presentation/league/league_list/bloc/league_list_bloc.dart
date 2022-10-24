import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/domain/repositories/league_repository.dart';
import 'package:game_note/domain/usecases/get_leagues.dart';

import '../../../../domain/entities/league_model.dart';

part 'league_list_event.dart';
part 'league_list_state.dart';

class LeagueListBloc extends Bloc<LeagueListEvent, LeagueListState> {
  final GetLeagues getLeagues;
  LeagueListBloc({required this.getLeagues}) : super(const LeagueListState()) {
    on<LeagueListStarted>(_onStarted);
  }

  _onStarted(LeagueListStarted event, Emitter<LeagueListState> emit) async {
    emit(state.copyWith(status: LeagueListStatus.loading));
    var result = await getLeagues.call(GetLeaguesParams());
    result.fold(
      (l) => emit(state.copyWith(status: LeagueListStatus.error)),
      (r) => emit(state.copyWith(status: LeagueListStatus.loaded, leagues: r)),
    );
  }
}
