import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';

import '../../../../firebase/firestore/esport/league/gn_esport_league.dart';

part 'tournament_event.dart';
part 'tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  final EsportLeagueRepository _esportLeagueRepository;
  TournamentBloc(this._esportLeagueRepository)
      : super(const TournamentState()) {
    on<GetTournaments>(_getTournaments);
    on<AddTournament>(_addTournament);

    _leaguesSubscription =
        _esportLeagueRepository.listenForLeagues().listen((leagues) {
      add(GetTournaments());
    });
  }

  StreamSubscription<List<GNEsportLeague>>? _leaguesSubscription;

  void _getTournaments(
      GetTournaments event, Emitter<TournamentState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final leagues = await _esportLeagueRepository.getLeagues();
      emit(state.copyWith(viewStatus: ViewStatus.success, leagues: leagues));
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  void _addTournament(
      AddTournament event, Emitter<TournamentState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.addLeague(
        name: event.name,
        groupId: event.groupId,
        startDate: event.startDate,
        endDate: event.endDate,
        description: event.description,
      );
      add(GetTournaments());
      showToast('Tạo giải đấu thành công');
    } catch (e) {
      emit(state.copyWith(
          viewStatus: ViewStatus.failure, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _leaguesSubscription?.cancel();
    return super.close();
  }
}
