import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/cache/h2h_preferences.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/widgets/shimmer.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/detail/dashboard_detail_page.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/dashboard/models/league_performance_point.dart';
import 'package:pes_arena/presentation/home/dashboard/models/opponent_stat.dart';
import 'package:pes_arena/presentation/home/dashboard/models/recent_match_summary.dart';

class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

DashboardStats _stats({
  int matchesPlayed = 106,
  int wins = 60,
  int draws = 20,
  int losses = 26,
  int goals = 180,
  int goalsConceded = 90,
  int champion = 39,
  int runnerUp = 22,
  int finished = 105,
  int joined = 12,
  DateTime? lastChampionAt,
  List<RecentMatchSummary> recentMatches = const [],
  List<LeaguePerformancePoint> leaguePerformance = const [],
  List<OpponentStat> opponents = const [],
}) {
  return DashboardStats(
    tournamentsJoined: joined,
    finishedTournaments: finished,
    championCount: champion,
    runnerUpCount: runnerUp,
    lastChampionAt: lastChampionAt ?? DateTime(2026, 5, 3),
    matchesPlayed: matchesPlayed,
    wins: wins,
    draws: draws,
    losses: losses,
    goals: goals,
    goalsConceded: goalsConceded,
    recentMatches: recentMatches,
    leaguePerformance: leaguePerformance,
    opponents: opponents,
  );
}

RecentMatchSummary _match(String id, MatchResult r) => RecentMatchSummary(
  matchId: id,
  leagueId: 'l1',
  leagueName: 'Cup',
  date: DateTime(2026, 5, 1),
  userScore: r == MatchResult.win ? 3 : 1,
  opponentScore: r == MatchResult.loss ? 3 : 1,
  opponentDisplayName: 'Opp',
  result: r,
);

void main() {
  late _MockDashboardBloc bloc;

  setUpAll(() {
    registerFallbackValue(LoadDashboard());
    registerFallbackValue(RefreshDashboard());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    bloc = _MockDashboardBloc();
    getIt.registerFactory<DashboardBloc>(() => bloc);
    getIt.registerSingleton<H2HPreferences>(H2HPreferences(prefs));
  });

  tearDown(() => getIt.reset());

  Widget wrap() => MaterialApp.router(
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardDetailPage(),
        ),
        GoRoute(
          path: '/tournament/:leagueId',
          builder: (_, state) =>
              Text('tournament ${state.pathParameters['leagueId']}'),
        ),
      ],
    ),
  );

  testWidgets('render đầy đủ các metric trong section Tổng quan', (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: _stats(
          recentMatches: [
            _match('m1', MatchResult.win),
            _match('m2', MatchResult.loss),
          ],
        ),
      ),
    );

    await tester.pumpWidget(wrap());

    // Labels
    expect(find.text('Số giải tham gia'), findsOneWidget);
    expect(find.text('Số trận'), findsOneWidget);
    expect(find.text('Vô địch gần nhất'), findsOneWidget);
    expect(find.text('Thắng / Hoà / Thua'), findsOneWidget);
    expect(find.text('Tỉ lệ T / H / T'), findsOneWidget);
    expect(find.text('BT / BB / Hiệu số'), findsOneWidget);
    expect(find.text('Vô địch'), findsOneWidget);
    expect(find.text('Á quân'), findsOneWidget);

    // Computed values
    expect(find.text('12'), findsOneWidget); // joined
    expect(find.text('106'), findsOneWidget); // matches
    expect(find.text('60 / 20 / 26'), findsOneWidget); // W/D/L counts
    expect(find.text('57% / 19% / 25%'), findsOneWidget); // W/D/L pct (rounded)
    expect(find.text('180 / 90 / +90'), findsOneWidget); // goals diff
    expect(find.text('39 - 37%'), findsOneWidget); // champion 39/105
    expect(find.text('22 - 21%'), findsOneWidget); // runner-up 22/105
    expect(find.text('03/05/2026'), findsOneWidget); // last champion date
  });

  testWidgets('hiển thị "—" khi chưa đấu trận / chưa kết thúc giải nào', (
    tester,
  ) async {
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

    await tester.pumpWidget(wrap());

    expect(find.text('— / — / —'), findsOneWidget); // win-rate row
    expect(find.text('0 - —'), findsNWidgets(2)); // champion + runner-up
    // 1 lastChampionAt + 2 H2H rows (no opponents qualify).
    expect(find.text('—'), findsNWidgets(3));
    // Empty H2H placeholder hint.
    expect(find.textContaining('Cần ≥ 50 trận'), findsNWidgets(2));
    // Scroll to reveal chart placeholder + recent-matches section.
    await tester.scrollUntilVisible(
      find.text('Chưa đủ dữ liệu để vẽ biểu đồ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Chưa đủ dữ liệu để vẽ biểu đồ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Trận gần đây'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // FormDotsRow shows its own empty placeholder; detail page adds one.
    expect(find.text('Chưa có trận nào'), findsNWidgets(2));
  });

  testWidgets('hiệu số 0 không hiển thị dấu cộng', (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: _stats(goals: 50, goalsConceded: 50),
      ),
    );
    await tester.pumpWidget(wrap());
    expect(find.text('50 / 50 / 0'), findsOneWidget);
  });

  testWidgets('hiệu số âm hiển thị dấu trừ', (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: _stats(goals: 30, goalsConceded: 50),
      ),
    );
    await tester.pumpWidget(wrap());
    expect(find.text('30 / 50 / -20'), findsOneWidget);
  });

  testWidgets('loading + null stats render shimmer skeleton', (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(const DashboardState(viewStatus: ViewStatus.loading));
    await tester.pumpWidget(wrap());
    // Shimmer in body. AppBar refresh icon shows its own spinner
    // (CircularProgressIndicator) — body uses shimmer, no Circular here.
    expect(find.byType(Shimmer), findsOneWidget);
    expect(find.byType(ShimmerBox), findsWidgets);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('failure + null stats render error + Thử lại dispatch Load', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      const DashboardState(
        viewStatus: ViewStatus.failure,
        errorMessage: 'boom',
      ),
    );
    await tester.pumpWidget(wrap());
    expect(find.text('boom'), findsOneWidget);

    // BlocProvider already fires LoadDashboard on creation; tap fires a 2nd.
    await tester.tap(find.text('Thử lại'));
    verify(() => bloc.add(any(that: isA<LoadDashboard>()))).called(2);
  });

  testWidgets('failure không message dùng fallback', (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(const DashboardState(viewStatus: ViewStatus.failure));
    await tester.pumpWidget(wrap());
    expect(find.text('Lỗi tải dữ liệu'), findsOneWidget);
  });

  testWidgets('AppBar refresh icon mở dialog xác nhận, "Cập nhật" → dispatch',
      (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(DashboardState(viewStatus: ViewStatus.success, stats: _stats()));
    await tester.pumpWidget(wrap());
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(find.text('Cập nhật thống kê?'), findsOneWidget);
    // Confirm
    await tester.tap(find.widgetWithText(FilledButton, 'Cập nhật'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(any(that: isA<RefreshDashboard>()))).called(1);
  });

  testWidgets('AppBar refresh dialog "Huỷ" không dispatch', (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(DashboardState(viewStatus: ViewStatus.success, stats: _stats()));
    await tester.pumpWidget(wrap());
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Huỷ'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<RefreshDashboard>())));
  });

  testWidgets('AppBar refresh button disable khi đang loading + spinner', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      DashboardState(viewStatus: ViewStatus.loading, stats: _stats()),
    );
    await tester.pumpWidget(wrap());
    // Find the AppBar refresh action by tooltip text — H2H section also
    // has its own IconButton.
    final iconButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Cập nhật từ máy chủ'),
        matching: find.byType(IconButton),
      ),
    );
    expect(iconButton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('loading với stats cũ overlay shimmer bar phía trên ListView',
      (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(viewStatus: ViewStatus.loading, stats: _stats()),
    );
    await tester.pumpWidget(wrap());
    // Body has both: cached stats (Card visible) + shimmer overlay bar.
    expect(find.byType(Shimmer), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('không còn RefreshIndicator (refresh chỉ qua dialog)',
      (tester) async {
    when(
      () => bloc.state,
    ).thenReturn(DashboardState(viewStatus: ViewStatus.success, stats: _stats()));
    await tester.pumpWidget(wrap());
    expect(find.byType(RefreshIndicator), findsNothing);
  });

  testWidgets('render danh sách recent matches', (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: _stats(recentMatches: [_match('m1', MatchResult.win)]),
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
    expect(find.text('Trận gần đây'), findsOneWidget);
    expect(find.text('Opp'), findsOneWidget);
    expect(find.text('3 - 1'), findsOneWidget);
  });

  testWidgets('section Đối đầu: chọn theo tỉ lệ, qualifier theo default 50',
      (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: _stats(
          opponents: const [
            // Andy: 50% win — chỉ 30 trận → bị loại (chưa đủ 50).
            OpponentStat(
              opponentId: 'a',
              opponentDisplayName: 'Andy',
              matchesPlayed: 30,
              wins: 15,
              draws: 5,
              losses: 10,
            ),
            // Bob: 60 trận, thắng 36 (60%), thua 12 (20%).
            OpponentStat(
              opponentId: 'b',
              opponentDisplayName: 'Bob',
              matchesPlayed: 60,
              wins: 36,
              draws: 12,
              losses: 12,
            ),
            // Cole: 50 trận, thắng 10 (20%), thua 30 (60%) → khắc tinh.
            OpponentStat(
              opponentId: 'c',
              opponentDisplayName: 'Cole',
              matchesPlayed: 50,
              wins: 10,
              draws: 10,
              losses: 30,
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(wrap());
    expect(find.text('Đối đầu'), findsOneWidget);
    expect(find.text('KHẮC TINH'), findsOneWidget);
    expect(find.text('MỒI NGON'), findsOneWidget);
    // Tỉ lệ render lớn ở góc phải, tên và count trên dòng riêng.
    expect(find.text('60%'), findsNWidgets(2));
    expect(find.text('Cole'), findsOneWidget);
    expect(find.text('30 / 50 trận thua'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('36 / 60 trận thắng'), findsOneWidget);
    expect(find.textContaining('Andy'), findsNothing);
  });

  testWidgets('section Đối đầu: empty / không ai >=20 trận → "—" cho cả 2 dòng',
      (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: _stats(
          opponents: const [
            OpponentStat(
              opponentId: 'a',
              opponentDisplayName: 'Andy',
              matchesPlayed: 5,
              wins: 5,
              draws: 0,
              losses: 0,
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(wrap());
    // 2 H2H rows show "—" và placeholder hint.
    expect(find.text('—'), findsNWidgets(2));
    expect(find.textContaining('Cần ≥ 50 trận'), findsNWidgets(2));
  });

  testWidgets('mở bottom sheet, đổi slider, lưu → cập nhật ngưỡng + persist',
      (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: _stats(
          opponents: const [
            OpponentStat(
              opponentId: 'a',
              opponentDisplayName: 'Andy',
              matchesPlayed: 60,
              wins: 24,
              draws: 12,
              losses: 24,
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(wrap());
    expect(find.text('(≥ 50 trận)'), findsOneWidget);
    expect(find.text('Andy'), findsAtLeastNWidgets(1));
    expect(find.text('24 / 60 trận thắng'), findsOneWidget);

    // Open bottom sheet via tune icon.
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.text('Ngưỡng số trận tối thiểu'), findsOneWidget);

    // Drag the slider toward the right end (bigger min) and save.
    await tester.drag(find.byType(Slider), const Offset(500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    // Threshold updated; Andy filtered out (only 60 < new high).
    expect(find.text('(≥ 50 trận)'), findsNothing);
    expect(find.textContaining('Andy'), findsNothing);

    // Persisted to SharedPreferences via the registered H2HPreferences.
    final stored = getIt<H2HPreferences>().minMatches;
    expect(stored, greaterThan(60));
  });

  testWidgets('bottom sheet — Huỷ không thay đổi ngưỡng', (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(viewStatus: ViewStatus.success, stats: _stats()),
    );
    await tester.pumpWidget(wrap());
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Huỷ'));
    await tester.pumpAndSettle();
    expect(find.text('(≥ 50 trận)'), findsOneWidget);
    expect(getIt<H2HPreferences>().minMatches, 50);
  });

  testWidgets('khởi tạo dùng giá trị đã lưu trong H2HPreferences', (
    tester,
  ) async {
    // Re-register prefs with a non-default value.
    getIt.unregister<H2HPreferences>();
    SharedPreferences.setMockInitialValues({
      'dashboard.h2h.min_matches': 50,
    });
    final sp = await SharedPreferences.getInstance();
    getIt.registerSingleton<H2HPreferences>(H2HPreferences(sp));

    when(() => bloc.state).thenReturn(
      DashboardState(viewStatus: ViewStatus.success, stats: _stats()),
    );
    await tester.pumpWidget(wrap());
    expect(find.text('(≥ 50 trận)'), findsOneWidget);
    expect(find.textContaining('Cần ≥ 50 trận'), findsNWidgets(2));
  });

  test('pickTopByRate: tie-break theo matchesPlayed khi cùng tỉ lệ', () {
    final result = pickTopByRate(
      const [
        OpponentStat(
          opponentId: 'a',
          opponentDisplayName: 'Andy',
          matchesPlayed: 20,
          wins: 10,
          draws: 0,
          losses: 10,
        ),
        OpponentStat(
          opponentId: 'b',
          opponentDisplayName: 'Bob',
          matchesPlayed: 40,
          wins: 20,
          draws: 0,
          losses: 20,
        ),
      ],
      (o) => o.wins,
      minMatches: 20,
    );
    // Both 50% win rate → Bob wins on more games played.
    expect(result?.opponentId, 'b');
  });

  test('pickTopByRate: bỏ qua opponent có rate = 0 dù đủ trận', () {
    final result = pickTopByRate(
      const [
        OpponentStat(
          opponentId: 'a',
          opponentDisplayName: 'Andy',
          matchesPlayed: 25,
          wins: 0,
          draws: 25,
          losses: 0,
        ),
      ],
      (o) => o.wins,
      minMatches: 20,
    );
    expect(result, isNull);
  });

  testWidgets('render section "Phong độ 5 giải gần nhất" và chart placeholder',
      (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(viewStatus: ViewStatus.success, stats: _stats()),
    );
    await tester.pumpWidget(wrap());
    await tester.scrollUntilVisible(
      find.text('Phong độ 5 giải gần nhất'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Phong độ 5 giải gần nhất'), findsOneWidget);
    expect(find.text('Chưa đủ dữ liệu để vẽ biểu đồ'), findsOneWidget);
  });

  testWidgets('chart hiện khi có league performance', (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: _stats(
          leaguePerformance: [
            LeaguePerformancePoint(
              leagueId: 'l1',
              leagueName: 'Cup',
              lastPlayedAt: DateTime(2026, 1, 1),
              matchesPlayed: 5,
              wins: 3,
              draws: 1,
              losses: 1,
              pointsPerMatch: 2.0,
              goalDifferencePerMatch: 0.6,
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.scrollUntilVisible(
      find.text('Điểm / trận'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Điểm / trận'), findsOneWidget);
    expect(find.text('Hiệu số / trận'), findsOneWidget);
  });

  testWidgets('tap match item → push route tournament detail', (tester) async {
    when(() => bloc.state).thenReturn(
      DashboardState(
        viewStatus: ViewStatus.success,
        stats: _stats(recentMatches: [_match('m1', MatchResult.win)]),
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.scrollUntilVisible(
      find.text('Opp'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Opp'));
    await tester.pumpAndSettle();
    expect(find.text('tournament l1'), findsOneWidget);
  });
}
