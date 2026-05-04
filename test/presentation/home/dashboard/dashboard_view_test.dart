import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/dashboard_view.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/dashboard/models/recent_match_summary.dart';

class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

Widget _wrap(DashboardBloc bloc) => MaterialApp(
  home: BlocProvider<DashboardBloc>.value(
    value: bloc,
    child: const Scaffold(body: DashboardView()),
  ),
);

RecentMatchSummary _match() => RecentMatchSummary(
  matchId: 'm1',
  leagueId: 'l1',
  leagueName: 'League',
  date: DateTime(2026, 5, 3),
  userScore: 2,
  opponentScore: 1,
  opponentDisplayName: 'Nam',
  result: MatchResult.win,
);

void main() {
  setUpAll(() {
    registerFallbackValue(LoadDashboard());
    registerFallbackValue(RefreshDashboard());
  });

  testWidgets('initial state dispatch LoadDashboard và render empty shrink', (
    tester,
  ) async {
    final bloc = _MockDashboardBloc();
    when(() => bloc.state).thenReturn(const DashboardState());

    await tester.pumpWidget(_wrap(bloc));

    verify(() => bloc.add(any(that: isA<LoadDashboard>()))).called(1);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('loading không có stats render skeleton', (tester) async {
    final bloc = _MockDashboardBloc();
    when(
      () => bloc.state,
    ).thenReturn(const DashboardState(viewStatus: ViewStatus.loading));

    await tester.pumpWidget(_wrap(bloc));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(4));
  });

  testWidgets('failure không có stats render lỗi và retry', (tester) async {
    final bloc = _MockDashboardBloc();
    when(() => bloc.state).thenReturn(
      const DashboardState(
        viewStatus: ViewStatus.failure,
        errorMessage: 'boom',
      ),
    );

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('boom'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    verify(() => bloc.add(any(that: isA<LoadDashboard>()))).called(1);
  });

  testWidgets('failure không có message dùng fallback', (tester) async {
    final bloc = _MockDashboardBloc();
    when(
      () => bloc.state,
    ).thenReturn(const DashboardState(viewStatus: ViewStatus.failure));

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('Lỗi tải dữ liệu'), findsOneWidget);
  });

  testWidgets('success render stats, form và list', (tester) async {
    final bloc = _MockDashboardBloc();
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: DashboardStats(
          tournamentsJoined: 1,
          finishedTournaments: 1,
          championCount: 1,
          runnerUpCount: 0,
          lastChampionAt: DateTime.now(),
          recentMatches: [_match()],
        ),
      ),
    );

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('Phong độ 10 trận gần nhất'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Trận gần đây'), findsOneWidget);
    expect(find.text('Bạn 2 - 1 Nam'), findsOneWidget);
  });

  testWidgets('success empty render empty text cho form và list', (
    tester,
  ) async {
    final bloc = _MockDashboardBloc();
    when(() => bloc.state).thenReturn(
      const DashboardState(
        viewStatus: ViewStatus.success,
        stats: DashboardStats(
          tournamentsJoined: 0,
          finishedTournaments: 0,
          championCount: 0,
          runnerUpCount: 0,
          lastChampionAt: null,
          recentMatches: [],
        ),
      ),
    );

    await tester.pumpWidget(_wrap(bloc));

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Chưa có trận nào'), findsNWidgets(2));
  });

  testWidgets('loading với stats cũ giữ UI và hiện LinearProgressIndicator', (
    tester,
  ) async {
    final bloc = _MockDashboardBloc();
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.loading,
        stats: DashboardStats(
          tournamentsJoined: 1,
          finishedTournaments: 1,
          championCount: 1,
          runnerUpCount: 0,
          lastChampionAt: DateTime.now(),
          recentMatches: [_match()],
        ),
      ),
    );

    await tester.pumpWidget(_wrap(bloc));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Bạn 2 - 1 Nam'), findsOneWidget);
  });

  testWidgets('pull to refresh dispatch RefreshDashboard', (tester) async {
    final bloc = _MockDashboardBloc();
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: DashboardStats(
          tournamentsJoined: 1,
          finishedTournaments: 1,
          championCount: 1,
          runnerUpCount: 0,
          lastChampionAt: DateTime.now(),
          recentMatches: const [],
        ),
      ),
    );

    await tester.pumpWidget(_wrap(bloc));
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => bloc.add(any(that: isA<RefreshDashboard>()))).called(1);
  });
}
