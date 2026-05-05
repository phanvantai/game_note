import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/presentation/home/dashboard/models/recent_match_summary.dart';
import 'package:pes_arena/presentation/home/dashboard/widgets/form_dots_row.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

RecentMatchSummary _summary(MatchResult result) => RecentMatchSummary(
  matchId: result.name,
  leagueId: 'l1',
  leagueName: 'League',
  date: DateTime(2026, 1, 1),
  userScore: 1,
  opponentScore: 0,
  opponentDisplayName: 'Opponent',
  result: result,
);

void main() {
  testWidgets('empty state khi chưa có trận', (tester) async {
    await tester.pumpWidget(_wrap(const FormDotsRow(matches: [])));

    expect(find.text('Chưa có trận nào'), findsOneWidget);
  });

  testWidgets('render đúng số dot theo số trận', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FormDotsRow(
          matches: [
            _summary(MatchResult.win),
            _summary(MatchResult.draw),
            _summary(MatchResult.loss),
          ],
        ),
      ),
    );

    expect(find.byType(Container), findsNWidgets(3));
  });

  testWidgets('extension màu/icon/label đúng theo result', (tester) async {
    expect(MatchResult.win.color, Colors.green);
    expect(MatchResult.draw.color, Colors.amber);
    expect(MatchResult.loss.color, Colors.red);
    expect(MatchResult.win.icon, Icons.check_circle);
    expect(MatchResult.draw.icon, Icons.remove_circle);
    expect(MatchResult.loss.icon, Icons.cancel);
    expect(MatchResult.win.label, 'T');
    expect(MatchResult.draw.label, 'H');
    expect(MatchResult.loss.label, 'B');
  });
}
