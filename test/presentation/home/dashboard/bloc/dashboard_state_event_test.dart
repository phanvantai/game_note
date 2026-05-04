import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';

void main() {
  test('DashboardEvent props', () {
    expect(LoadDashboard().props, isEmpty);
    expect(RefreshDashboard().props, isEmpty);
  });

  test('DashboardState copyWith giữ hoặc clear stats đúng semantics', () {
    const stats = DashboardStats(
      tournamentsJoined: 1,
      finishedTournaments: 1,
      championCount: 1,
      runnerUpCount: 0,
      lastChampionAt: null,
      recentMatches: [],
    );
    const state = DashboardState(stats: stats);

    expect(state.copyWith(viewStatus: ViewStatus.loading).stats, stats);
    expect(state.copyWith(stats: null).stats, isNull);
    expect(state.copyWith(errorMessage: 'err').errorMessage, 'err');
  });
}
