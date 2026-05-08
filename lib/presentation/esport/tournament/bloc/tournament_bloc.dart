import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';

import '../../../../firebase/firestore/esport/league/gn_esport_league.dart';

part 'tournament_event.dart';
part 'tournament_state.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  final EsportLeagueRepository _esportLeagueRepository;

  static const int _pageSize = 20;

  TournamentBloc(this._esportLeagueRepository)
    : super(const TournamentState()) {
    on<LoadMyLeagues>(_onLoadMyLeagues);
    on<LoadMoreMyLeagues>(_onLoadMoreMyLeagues);
    on<LoadManagedLeagues>(_onLoadManagedLeagues);
    on<LoadMoreManagedLeagues>(_onLoadMoreManagedLeagues);
    on<LoadOtherLeagues>(_onLoadOtherLeagues);
    on<LoadMoreOtherLeagues>(_onLoadMoreOtherLeagues);
    on<RefreshTournaments>(_onRefresh);
    add(LoadMyLeagues());
    add(LoadManagedLeagues());
    add(LoadOtherLeagues());
  }

  Future<void> _onLoadMyLeagues(
    LoadMyLeagues event,
    Emitter<TournamentState> emit,
  ) async {
    if (state.myLeagues.isEmpty) {
      emit(state.copyWith(myStatus: ViewStatus.loading));
    }
    try {
      final page = await _esportLeagueRepository.getMyLeagues(limit: _pageSize);
      emit(
        state.copyWith(
          myStatus: ViewStatus.success,
          myLeagues: page.items,
          myCursor: page.lastDoc,
          myHasMore: page.hasMore,
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

  Future<void> _onLoadMoreMyLeagues(
    LoadMoreMyLeagues event,
    Emitter<TournamentState> emit,
  ) async {
    if (state.myStatus == ViewStatus.loading || !state.myHasMore) return;
    emit(state.copyWith(myStatus: ViewStatus.loading));
    try {
      final page = await _esportLeagueRepository.getMyLeagues(
        startAfter: state.myCursor,
        limit: _pageSize,
      );
      emit(
        state.copyWith(
          myStatus: ViewStatus.success,
          myLeagues: [...state.myLeagues, ...page.items],
          myCursor: page.lastDoc ?? state.myCursor,
          myHasMore: page.hasMore,
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

  Future<void> _onLoadManagedLeagues(
    LoadManagedLeagues event,
    Emitter<TournamentState> emit,
  ) async {
    if (state.managedLeagues.isEmpty) {
      emit(state.copyWith(managedStatus: ViewStatus.loading));
    }
    try {
      final page = await _esportLeagueRepository.getManagedLeagues(
        limit: _pageSize,
      );
      emit(
        state.copyWith(
          managedStatus: ViewStatus.success,
          managedLeagues: page.items,
          managedCursor: page.lastDoc,
          managedHasMore: page.hasMore,
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          managedStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMoreManagedLeagues(
    LoadMoreManagedLeagues event,
    Emitter<TournamentState> emit,
  ) async {
    if (state.managedStatus == ViewStatus.loading || !state.managedHasMore) {
      return;
    }
    emit(state.copyWith(managedStatus: ViewStatus.loading));
    try {
      final page = await _esportLeagueRepository.getManagedLeagues(
        startAfter: state.managedCursor,
        limit: _pageSize,
      );
      emit(
        state.copyWith(
          managedStatus: ViewStatus.success,
          managedLeagues: [...state.managedLeagues, ...page.items],
          managedCursor: page.lastDoc ?? state.managedCursor,
          managedHasMore: page.hasMore,
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          managedStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadOtherLeagues(
    LoadOtherLeagues event,
    Emitter<TournamentState> emit,
  ) async {
    if (state.otherLeagues.isEmpty) {
      emit(state.copyWith(otherStatus: ViewStatus.loading));
    }
    try {
      final page = await _esportLeagueRepository.getOtherLeagues(
        limit: _pageSize,
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
    if (state.otherStatus == ViewStatus.loading || !state.otherHasMore) return;
    emit(state.copyWith(otherStatus: ViewStatus.loading));
    try {
      final page = await _esportLeagueRepository.getOtherLeagues(
        startAfter: state.otherCursor,
        limit: _pageSize,
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
    try {
      final results = await Future.wait([
        _esportLeagueRepository.getMyLeagues(limit: _pageSize),
        _esportLeagueRepository.getManagedLeagues(limit: _pageSize),
        _esportLeagueRepository.getOtherLeagues(limit: _pageSize),
      ]);
      final myPage = results[0];
      final managedPage = results[1];
      final otherPage = results[2];
      emit(
        state.copyWith(
          myStatus: ViewStatus.success,
          managedStatus: ViewStatus.success,
          otherStatus: ViewStatus.success,
          myLeagues: myPage.items,
          myCursor: myPage.lastDoc,
          myHasMore: myPage.hasMore,
          managedLeagues: managedPage.items,
          managedCursor: managedPage.lastDoc,
          managedHasMore: managedPage.hasMore,
          otherLeagues: otherPage.items,
          otherCursor: otherPage.lastDoc,
          otherHasMore: otherPage.hasMore,
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
}
