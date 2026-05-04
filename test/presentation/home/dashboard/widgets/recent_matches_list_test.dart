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
  opponentDisplayName: 'NamPhan',
  result: result,
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

    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('render match và tap đi tới tournament detail', (tester) async {
    await tester.pumpWidget(
      _wrap(RecentMatchesList(matches: [_summary(MatchResult.win)])),
    );

    expect(find.text('03/05 · Champions Cup'), findsOneWidget);
    expect(find.text('Bạn 3 - 1 NamPhan'), findsOneWidget);

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(find.text('detail l1'), findsOneWidget);
  });
}
