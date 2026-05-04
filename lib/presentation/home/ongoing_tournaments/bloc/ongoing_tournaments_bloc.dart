import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';

part 'ongoing_tournaments_event.dart';
part 'ongoing_tournaments_state.dart';

class OngoingTournamentsBloc
    extends Bloc<OngoingTournamentsEvent, OngoingTournamentsState> {
  final EsportLeagueRepository _repository;

  OngoingTournamentsBloc(this._repository)
    : super(const OngoingTournamentsState()) {
    on<LoadOngoingTournaments>(_onLoad);
  }

  Future<void> _onLoad(
    LoadOngoingTournaments event,
    Emitter<OngoingTournamentsState> emit,
  ) async {
    if (event.groupIds.isEmpty) {
      emit(
        state.copyWith(
          status: ViewStatus.success,
          leagues: const [],
          loadedGroupIds: const [],
        ),
      );
      return;
    }

    emit(state.copyWith(status: ViewStatus.loading));
    try {
      final leagues = await _repository.getActiveLeaguesByGroupIds(
        event.groupIds,
      );
      emit(
        state.copyWith(
          status: ViewStatus.success,
          leagues: leagues,
          loadedGroupIds: event.groupIds,
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
