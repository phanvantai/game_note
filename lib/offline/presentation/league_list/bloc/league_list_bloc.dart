import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/offline/domain/repositories/league_repository.dart';
import 'package:game_note/offline/domain/usecases/delete_league.dart';
import 'package:game_note/offline/domain/usecases/get_leagues.dart';

import '../../../domain/entities/league_model.dart';
import '../../../domain/usecases/create_league.dart';

part 'league_list_event.dart';
part 'league_list_state.dart';

class LeagueListBloc extends Bloc<LeagueListEvent, LeagueListState> {
  final GetLeagues getLeagues;
  final CreateLeague createLeague;
  final DeleteLeague deleteLeague;
  LeagueListBloc({
    required this.getLeagues,
    required this.createLeague,
    required this.deleteLeague,
  }) : super(const LeagueListState()) {
    on<LeagueListStarted>(_onStarted);
    on<DeleteLeagueEvent>(_onDeleteLeague);
    on<CreateLeagueEvent>(_onCreateLeague);
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

  _onCreateLeague(
      CreateLeagueEvent event, Emitter<LeagueListState> emit) async {
    emit(state.copyWith(status: LeagueListStatus.loading));
    // create league
    var now = DateTime.now();
    var name = '${now.year}-${now.month}-${now.day} ${event.name}';
    var result = await createLeague.call(CreateLeagueParams(name));
    result.fold(
      (l) => emit(state.copyWith(status: LeagueListStatus.error)),
      (r) =>
          emit(state.copyWith(status: LeagueListStatus.loaded, newLeague: r)),
    );
  }
}
