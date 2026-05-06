import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/presentation/home/dashboard/models/recent_match_summary.dart';
import 'package:pes_arena/presentation/home/dashboard/widgets/recent_matches_list.dart';

RecentMatchSummary _summary(MatchResult result) => RecentMatchSummary(
  matchId: 'm1',
  leagueId: 'l1',
  leagueName: 'Champions Cup',
  date: DateTime(2026, 5, 3),
  userScore: 3,
  opponentScore: 1,
  result: result,
  opponentDisplayName: 'NamPhan',
);

Widget _wrap(Widget child) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(body: child),
        ),
        GoRoute(
          path: '/tournament/:leagueId',
          builder: (context, state) =>
              Text('detail ${state.pathParameters['leagueId']}'),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('empty list render SizedBox', (tester) async {
    await tester.pumpWidget(_wrap(const RecentMatchesList(matches: [])));

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('render avatar, tên đối thủ, giải đấu, tỉ số và result badge',
      (tester) async {
    await tester.pumpWidget(
      _wrap(RecentMatchesList(matches: [_summary(MatchResult.win)])),
    );

    expect(find.text('NamPhan'), findsOneWidget);
    expect(find.text('Champions Cup'), findsOneWidget);
    expect(find.text('3 - 1'), findsOneWidget);
    // Win result badge shows 'T'
    expect(find.text('T'), findsOneWidget);
    // Initials avatar 'N' from 'NamPhan'
    expect(find.text('N'), findsOneWidget);
  });

  testWidgets('tap đi tới tournament detail', (tester) async {
    await tester.pumpWidget(
      _wrap(RecentMatchesList(matches: [_summary(MatchResult.win)])),
    );

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(find.text('detail l1'), findsOneWidget);
  });

  testWidgets('result badge hiển thị đúng T/H/B theo kết quả', (tester) async {
    await tester.pumpWidget(
      _wrap(
        RecentMatchesList(
          matches: [
            _summary(MatchResult.win),
            RecentMatchSummary(
              matchId: 'm2',
              leagueId: 'l2',
              leagueName: 'Cup 2',
              date: DateTime(2026, 5, 4),
              userScore: 0,
              opponentScore: 0,
              result: MatchResult.draw,
              opponentDisplayName: 'Player B',
            ),
            RecentMatchSummary(
              matchId: 'm3',
              leagueId: 'l3',
              leagueName: 'Cup 3',
              date: DateTime(2026, 5, 5),
              userScore: 0,
              opponentScore: 2,
              result: MatchResult.loss,
              opponentDisplayName: 'Player C',
            ),
          ],
        ),
      ),
    );

    expect(find.text('T'), findsOneWidget);
    expect(find.text('H'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}
