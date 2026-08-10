import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item.dart';

GNEsportMatch _match({
  required bool isFinished,
  int? homeScore,
  int? awayScore,
  DateTime? date,
  GNUser? homeTeam,
  GNUser? awayTeam,
  int? matchday,
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
  matchday: matchday,
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

Widget _wrap(Widget child, {Locale locale = const Locale('vi')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets(
    'pending match shows localized progress semantics and ignores gestures',
    (tester) async {
      var taps = 0;
      var longPresses = 0;

      await tester.pumpWidget(
        _wrap(
          EsportMatchItem(
            match: _match(
              isFinished: true,
              homeScore: 2,
              awayScore: 1,
              homeTeam: _user('h1', 'Home Team'),
              awayTeam: _user('a1', 'Away Team'),
            ),
            isPending: true,
            onTap: () => taps++,
            onLongPress: () => longPresses++,
          ),
        ),
      );

      expect(find.text('Đang lưu kết quả'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.getSize(find.byType(CircularProgressIndicator)).longestSide,
        lessThanOrEqualTo(24),
      );

      final semanticsHandle = tester.ensureSemantics();
      final pendingSemantics = tester.getSemantics(
        find.bySemanticsLabel('Đang lưu kết quả'),
      );
      expect(pendingSemantics.label, 'Đang lưu kết quả');
      expect(pendingSemantics.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        pendingSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      expect(
        pendingSemantics.getSemanticsData().hasAction(
          SemanticsAction.longPress,
        ),
        isFalse,
      );
      expect(find.bySemanticsLabel('Home Team'), findsOneWidget);
      expect(find.bySemanticsLabel('Away Team'), findsOneWidget);
      semanticsHandle.dispose();

      await tester.tap(find.byType(InkWell), warnIfMissed: false);
      await tester.longPress(find.byType(InkWell), warnIfMissed: false);
      await tester.pump();

      expect(taps, 0);
      expect(longPresses, 0);
    },
  );

  testWidgets(
    'error message is readable and non-pending row stays interactive',
    (tester) async {
      var taps = 0;
      var longPresses = 0;

      await tester.pumpWidget(
        _wrap(
          EsportMatchItem(
            match: _match(
              isFinished: true,
              homeScore: 2,
              awayScore: 1,
              homeTeam: _user('h1', 'Home Team'),
              awayTeam: _user('a1', 'Away Team'),
            ),
            errorMessage: 'Không thể lưu kết quả. Vui lòng thử lại.',
            onTap: () => taps++,
            onLongPress: () => longPresses++,
          ),
        ),
      );

      expect(
        find.text('Không thể lưu kết quả. Vui lòng thử lại.'),
        findsOneWidget,
      );

      await tester.tap(find.byType(InkWell));
      await tester.longPress(find.byType(InkWell));
      await tester.pump();

      expect(taps, 1);
      expect(longPresses, 1);
    },
  );

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

  testWidgets('hiển thị badge vòng đấu bằng tiếng Việt', (tester) async {
    await tester.pumpWidget(
      _wrap(
        EsportMatchItem(
          match: _match(
            isFinished: false,
            matchday: 3,
            homeTeam: _user('h1', 'Home Team'),
            awayTeam: _user('a1', 'Away Team'),
          ),
        ),
      ),
    );

    expect(find.text('V3'), findsOneWidget);
  });

  testWidgets('hiển thị badge vòng đấu bằng tiếng Anh', (tester) async {
    await tester.pumpWidget(
      _wrap(
        EsportMatchItem(
          match: _match(
            isFinished: false,
            matchday: 3,
            homeTeam: _user('h1', 'Home Team'),
            awayTeam: _user('a1', 'Away Team'),
          ),
        ),
        locale: const Locale('en'),
      ),
    );

    expect(find.text('MD 3'), findsOneWidget);
  });

  testWidgets('không hiển thị badge khi trận không thuộc vòng nào', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        EsportMatchItem(
          match: _match(
            isFinished: false,
            homeTeam: _user('h1', 'Home Team'),
            awayTeam: _user('a1', 'Away Team'),
          ),
        ),
      ),
    );

    expect(find.textContaining('V'), findsNothing);
    expect(find.textContaining('MD'), findsNothing);
  });
}
