import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_event.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_state.dart';

class LeagueDetailBloc extends Bloc<LeagueDetailEvent, LeagueDetailState> {
  LeagueDetailBloc() : super(const LeagueDetailState()) {
    on<InitilizeLeagueEvent>(_initlize);
  }

  _initlize(InitilizeLeagueEvent event, Emitter<LeagueDetailState> emit) {
    emit(state.copyWith(status: LeagueDetailStatus.loaded, model: event.model));
  }
}
