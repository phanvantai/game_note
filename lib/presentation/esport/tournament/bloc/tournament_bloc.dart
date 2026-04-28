import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';

import '../../../../firebase/firestore/esport/league/gn_esport_league.dart';

part 'tournament_event.dart';
part 'tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  final EsportLeagueRepository _esportLeagueRepository;

  static const int _otherPageSize = 20;

  TournamentBloc(this._esportLeagueRepository)
    : super(const TournamentState()) {
    on<LoadMyLeagues>(_onLoadMyLeagues);
    on<LoadOtherLeagues>(_onLoadOtherLeagues);
    on<LoadMoreOtherLeagues>(_onLoadMoreOtherLeagues);
    on<RefreshTournaments>(_onRefresh);
    on<AddTournament>(_onAddTournament);

    // Kick off both tabs on construction so the screen has data ready
    // before the user touches a tab. The two queries run in parallel.
    add(LoadMyLeagues());
    add(LoadOtherLeagues());
  }

  Future<void> _onLoadMyLeagues(
    LoadMyLeagues event,
    Emitter<TournamentState> emit,
  ) async {
    final isInitial = state.myLeagues.isEmpty;
    if (isInitial) {
      emit(state.copyWith(myStatus: ViewStatus.loading));
    }
    try {
      final leagues = await _esportLeagueRepository.getMyLeagues();
      emit(
        state.copyWith(
          myStatus: ViewStatus.success,
          myLeagues: leagues,
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          myStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadOtherLeagues(
    LoadOtherLeagues event,
    Emitter<TournamentState> emit,
  ) async {
    final isInitial = state.otherLeagues.isEmpty;
    if (isInitial) {
      emit(state.copyWith(otherStatus: ViewStatus.loading));
    }
    try {
      final page = await _esportLeagueRepository.getOtherLeagues(
        limit: _otherPageSize,
      );
      emit(
        state.copyWith(
          otherStatus: ViewStatus.success,
          otherLeagues: page.items,
          otherCursor: page.lastDoc,
          otherHasMore: page.hasMore,
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          otherStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMoreOtherLeagues(
    LoadMoreOtherLeagues event,
    Emitter<TournamentState> emit,
  ) async {
    // Guard: avoid duplicate triggers from scroll-near-bottom firing twice.
    if (state.otherStatus == ViewStatus.loading || !state.otherHasMore) {
      return;
    }
    emit(state.copyWith(otherStatus: ViewStatus.loading));
    try {
      final page = await _esportLeagueRepository.getOtherLeagues(
        startAfter: state.otherCursor,
        limit: _otherPageSize,
      );
      emit(
        state.copyWith(
          otherStatus: ViewStatus.success,
          otherLeagues: [...state.otherLeagues, ...page.items],
          otherCursor: page.lastDoc ?? state.otherCursor,
          otherHasMore: page.hasMore,
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          otherStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefresh(
    RefreshTournaments event,
    Emitter<TournamentState> emit,
  ) async {
    // Reset both lists and re-load. Pull-to-refresh entry point.
    try {
      final results = await Future.wait([
        _esportLeagueRepository.getMyLeagues(),
        _esportLeagueRepository.getOtherLeagues(limit: _otherPageSize),
      ]);
      final my = results[0] as List<GNEsportLeague>;
      final page = results[1] as LeaguesPage;
      emit(
        state.copyWith(
          myStatus: ViewStatus.success,
          otherStatus: ViewStatus.success,
          myLeagues: my,
          otherLeagues: page.items,
          otherCursor: page.lastDoc,
          otherHasMore: page.hasMore,
          errorMessage: '',
          refreshTick: state.refreshTick + 1,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: e.toString(),
          refreshTick: state.refreshTick + 1,
        ),
      );
    }
  }

  Future<void> _onAddTournament(
    AddTournament event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.copyWith(myStatus: ViewStatus.loading));
    try {
      await _esportLeagueRepository.addLeague(
        name: event.name,
        groupId: event.groupId,
        startDate: event.startDate,
        endDate: event.endDate,
        description: event.description,
        rankPayoutEnabled: event.rankPayoutEnabled,
        rankPayouts: event.rankPayouts,
        defaultMatchCost: event.defaultMatchCost,
      );
      add(LoadMyLeagues());
      showToast('Tạo giải đấu thành công');
    } catch (e) {
      emit(
        state.copyWith(
          myStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
