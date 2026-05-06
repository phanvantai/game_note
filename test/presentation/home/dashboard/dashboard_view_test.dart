import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/widgets/shimmer.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/dashboard_view.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/dashboard/models/recent_match_summary.dart';

class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

Widget _wrap(DashboardBloc bloc) => MaterialApp.router(
  routerConfig: GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider<DashboardBloc>.value(
          value: bloc,
          child: const Scaffold(body: DashboardView()),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const Text('detail-route'),
      ),
    ],
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
    // Shimmer skeleton renders 4 placeholder cards inside an animated
    // Shimmer wrapper.
    expect(find.byType(Shimmer), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(4));
    await tester.pump(const Duration(milliseconds: 100)); // tick animation
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

    expect(find.text('Xem chi tiết'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Phong độ 10 trận gần nhất'), findsOneWidget);
    expect(find.text('Trận gần đây'), findsOneWidget);
    expect(find.text('Nam'), findsOneWidget);
    expect(find.text('2 - 1'), findsOneWidget);
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

  testWidgets('loading với stats cũ giữ UI hiện hữu, không có progress bar', (
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

    // No skeleton / progress UI on home — the cached stats stay put.
    expect(find.byType(Shimmer), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Nam'), findsOneWidget);
    expect(find.text('2 - 1'), findsOneWidget);
  });

  testWidgets('tap "Xem chi tiết" → push route /dashboard', (tester) async {
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
    await tester.tap(find.text('Xem chi tiết'));
    await tester.pumpAndSettle();
    expect(find.text('detail-route'), findsOneWidget);
  });

  testWidgets('không có RefreshIndicator (refresh chỉ ở detail)', (
    tester,
  ) async {
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

    expect(find.byType(RefreshIndicator), findsNothing);
  });
}
