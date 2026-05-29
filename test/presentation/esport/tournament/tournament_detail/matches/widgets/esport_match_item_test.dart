import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item.dart';

GNEsportMatch _match({
  required bool isFinished,
  int? homeScore,
  int? awayScore,
  DateTime? date,
  GNUser? homeTeam,
  GNUser? awayTeam,
}) => GNEsportMatch(
  id: 'm1',
  homeTeamId: 'h1',
  awayTeamId: 'a1',
  homeScore: homeScore,
  awayScore: awayScore,
  date: date ?? DateTime(2026, 1, 1),
  isFinished: isFinished,
  leagueId: 'l1',
  homeTeam: homeTeam,
  awayTeam: awayTeam,
);

GNUser _user(String id, String name) => GNUser(
  id: id,
  displayName: name,
  phoneNumber: null,
  email: null,
  photoUrl: null,
  role: 'user',
  fcmToken: '',
);

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('render finished match with teams and call onTap', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        EsportMatchItem(
          match: _match(
            isFinished: true,
            homeScore: 3,
            awayScore: 1,
            homeTeam: _user('h1', 'Home Team'),
            awayTeam: _user('a1', 'Away Team'),
          ),
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('FT'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Home Team'), findsOneWidget);
    expect(find.text('Away Team'), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets(
    'render unfinished match without teams and show date + pending scores',
    (tester) async {
      final date = DateTime(2026, 2, 5);
      await tester.pumpWidget(
        _wrap(EsportMatchItem(match: _match(isFinished: false, date: date))),
      );
      await tester.pump();

      expect(find.text(DateFormat('d MMM').format(date)), findsOneWidget);
      expect(find.text('-'), findsNWidgets(2));
      expect(find.text('Home Team'), findsNothing);
      expect(find.text('Away Team'), findsNothing);
    },
  );

  testWidgets('call onLongPress for the match tile', (tester) async {
    var tapped = false;
    var longPressed = false;
    await tester.pumpWidget(
      _wrap(
        EsportMatchItem(
          match: _match(isFinished: true, homeScore: 0, awayScore: 0),
          onTap: () => tapped = true,
          onLongPress: () => longPressed = true,
        ),
      ),
    );

    await tester.longPress(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(longPressed, isTrue);
    expect(tapped, isFalse);
  });
}
