import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bracket/bracket_view.dart';

class _MockBloc extends MockBloc<TournamentDetailEvent, TournamentDetailState>
    implements TournamentDetailBloc {}

class _AdminTournamentDetailState extends TournamentDetailState {
  const _AdminTournamentDetailState({
    required super.matches,
    super.participants,
    super.pendingMatchIds,
    super.matchErrorsById,
  });

  @override
  bool get currentUserIsLeagueAdmin => true;
}

GNEsportMatch _knockoutMatch({
  String id = 'M1',
  String home = 'A',
  String away = 'B',
  int knockoutRound = 0,
  int knockoutSlot = 0,
  bool isFinished = false,
  int? homeScore,
  int? awayScore,
}) {
  return GNEsportMatch(
    id: id,
    homeTeamId: home,
    awayTeamId: away,
    date: DateTime(2026, 1, 1),
    isFinished: isFinished,
    leagueId: 'L1',
    knockoutRound: knockoutRound,
    knockoutSlot: knockoutSlot,
    homeScore: homeScore,
    awayScore: awayScore,
    phase: 'knockout',
  );
}

GNEsportLeagueStat _standing(String userId) => GNEsportLeagueStat(
  id: 'S_$userId',
  userId: userId,
  leagueId: 'L1',
  matchesPlayed: 1,
  goals: 2,
  goalsConceded: 1,
  wins: 1,
  draws: 0,
  losses: 0,
);

GNEsportMatch _groupMatch({String id = 'G1'}) => GNEsportMatch(
  id: id,
  homeTeamId: 'GROUP_HOME',
  awayTeamId: 'GROUP_AWAY',
  homeScore: 2,
  awayScore: 1,
  date: DateTime(2026, 1, 1),
  isFinished: true,
  leagueId: 'L1',
  phase: 'group',
  groupId: 'A',
);

Widget _wrap(Widget child, TournamentDetailBloc bloc) => MaterialApp(
  home: BlocProvider<TournamentDetailBloc>.value(
    value: bloc,
    child: Scaffold(body: child),
  ),
);

void main() {
  late _MockBloc bloc;

  setUp(() => bloc = _MockBloc());
  tearDown(() => bloc.close());

  group('BracketView — trạng thái rỗng', () {
    testWidgets('hiển thị thông báo khi không có knockout match', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(const TournamentDetailState());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(const BracketView(), bloc));

      expect(find.text('Chưa có bracket'), findsOneWidget);
      expect(find.byIcon(Icons.account_tree_outlined), findsOneWidget);
    });
  });

  group('BracketView — round labels', () {
    testWidgets('1 round → chỉ hiện "Chung kết"', (tester) async {
      final state = TournamentDetailState(
        matches: [_knockoutMatch(id: 'M1', knockoutRound: 0)],
      );
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(const BracketView(), bloc));
      await tester.pump();

      expect(find.text('Chung kết'), findsOneWidget);
      expect(find.text('Bán kết'), findsNothing);
    });

    testWidgets('2 rounds → "Bán kết" + "Chung kết"', (tester) async {
      final state = TournamentDetailState(
        matches: [
          _knockoutMatch(id: 'M1', knockoutRound: 0),
          _knockoutMatch(id: 'M2', knockoutRound: 1),
        ],
      );
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(const BracketView(), bloc));
      await tester.pump();

      expect(find.text('Bán kết'), findsOneWidget);
      expect(find.text('Chung kết'), findsOneWidget);
    });

    testWidgets('3 rounds → "Tứ kết" + "Bán kết" + "Chung kết"', (
      tester,
    ) async {
      final state = TournamentDetailState(
        matches: [
          _knockoutMatch(id: 'M1', knockoutRound: 0),
          _knockoutMatch(id: 'M2', knockoutRound: 1),
          _knockoutMatch(id: 'M3', knockoutRound: 2),
        ],
      );
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(const BracketView(), bloc));
      await tester.pump();

      expect(find.text('Tứ kết'), findsOneWidget);
      expect(find.text('Bán kết'), findsOneWidget);
      expect(find.text('Chung kết'), findsOneWidget);
    });

    testWidgets('sort matches trong cùng round theo knockoutSlot', (
      tester,
    ) async {
      final state = TournamentDetailState(
        matches: [
          _knockoutMatch(
            id: 'M2',
            home: 'Second',
            away: 'B',
            knockoutRound: 0,
            knockoutSlot: 2,
          ),
          _knockoutMatch(
            id: 'M1',
            home: 'First',
            away: 'A',
            knockoutRound: 0,
            knockoutSlot: 1,
          ),
        ],
      );
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(const BracketView(), bloc));
      await tester.pump();

      final firstTop = tester.getTopLeft(find.text('Firs')).dy;
      final secondTop = tester.getTopLeft(find.text('Seco')).dy;
      expect(firstTop, lessThan(secondTop));
    });

    testWidgets('buildWhen bỏ qua state không đổi matches', (tester) async {
      final matches = [_knockoutMatch(id: 'M1', knockoutRound: 0)];
      final initial = TournamentDetailState(matches: matches);
      final sameMatches = TournamentDetailState(
        matches: matches,
        refreshTick: 1,
      );
      when(() => bloc.state).thenReturn(initial);
      when(() => bloc.stream).thenAnswer((_) => Stream.value(sameMatches));

      await tester.pumpWidget(_wrap(const BracketView(), bloc));
      await tester.pumpAndSettle();

      expect(find.text('Chung kết'), findsOneWidget);
    });
  });

  group('BracketView — match card', () {
    testWidgets('hiển thị TBD khi home/away team rỗng', (tester) async {
      final state = TournamentDetailState(
        matches: [_knockoutMatch(id: 'M1', home: '', away: '')],
      );
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(const BracketView(), bloc));
      await tester.pump();

      expect(find.text('TBD'), findsAtLeast(1));
    });

    testWidgets('hiển thị score khi match isFinished', (tester) async {
      final state = TournamentDetailState(
        matches: [
          _knockoutMatch(
            id: 'M1',
            knockoutRound: 0,
            home: 'A',
            away: 'B',
            isFinished: true,
            homeScore: 3,
            awayScore: 1,
          ),
        ],
      );
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(const BracketView(), bloc));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('rút gọn id dài khi chưa có display name', (tester) async {
      final state = TournamentDetailState(
        matches: [
          _knockoutMatch(id: 'M1', home: 'HOME_LONG_ID', away: 'AWAY_LONG_ID'),
        ],
      );
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(const BracketView(), bloc));
      await tester.pump();

      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('AWAY'), findsOneWidget);
    });

    testWidgets('admin chạm trận knockout mở dialog cập nhật tỉ số', (
      tester,
    ) async {
      final state = _AdminTournamentDetailState(
        matches: [_knockoutMatch(id: 'M1', home: 'A', away: 'B')],
      );
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(const BracketView(), bloc));
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets(
      'match error stays on its interactive card and pending hides stale error',
      (tester) async {
        final controller = StreamController<TournamentDetailState>.broadcast();
        final matches = [
          _knockoutMatch(id: 'M1', home: 'FAIL', away: 'WAIT'),
          _knockoutMatch(id: 'M2', home: 'SAFE', away: 'PLAY'),
        ];
        const errorMessage = 'Không lưu được trận M1';
        final errorState = _AdminTournamentDetailState(
          matches: matches,
          matchErrorsById: const {'M1': errorMessage},
        );
        when(() => bloc.state).thenReturn(errorState);
        when(() => bloc.stream).thenAnswer((_) => controller.stream);

        await tester.pumpWidget(_wrap(const BracketView(), bloc));

        final errorCard = find.ancestor(
          of: find.text('FAIL'),
          matching: find.byType(GestureDetector),
        );
        final ordinaryCard = find.ancestor(
          of: find.text('SAFE'),
          matching: find.byType(GestureDetector),
        );
        expect(errorCard, findsOneWidget);
        expect(ordinaryCard, findsOneWidget);
        expect(
          find.descendant(of: errorCard, matching: find.text(errorMessage)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: ordinaryCard, matching: find.text(errorMessage)),
          findsNothing,
        );

        await tester.tap(find.text('FAIL'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('Huỷ'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        controller.add(
          _AdminTournamentDetailState(
            matches: matches,
            pendingMatchIds: const {'M1'},
            matchErrorsById: const {'M1': errorMessage},
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Đang lưu kết quả'), findsOneWidget);
        expect(find.text(errorMessage), findsNothing);
        await tester.tap(find.text('FAIL'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(AlertDialog), findsNothing);

        await controller.close();
      },
    );

    testWidgets(
      'pending knockout locks only its card and standings updates keep rounds',
      (tester) async {
        final controller = StreamController<TournamentDetailState>.broadcast();
        final matches = [
          _knockoutMatch(id: 'M1', home: 'LOCK', away: 'WAIT'),
          _knockoutMatch(id: 'M2', home: 'OPEN', away: 'PLAY'),
          _groupMatch(),
        ];
        final initialState = _AdminTournamentDetailState(
          matches: matches,
          pendingMatchIds: const {'M1'},
        );
        when(() => bloc.state).thenReturn(initialState);
        when(() => bloc.stream).thenAnswer((_) => controller.stream);

        await tester.pumpWidget(_wrap(const BracketView(), bloc));

        expect(find.text('Đang lưu kết quả'), findsOneWidget);
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
        semanticsHandle.dispose();

        await tester.tap(find.text('LOCK'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(AlertDialog), findsNothing);

        await tester.tap(find.text('OPEN'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('Huỷ'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final bracketRounds = find.byKey(
          const Key('tournament-bracket-rounds'),
        );
        expect(bracketRounds, findsOneWidget);
        final initialRounds = tester.widget(bracketRounds);

        controller.add(
          _AdminTournamentDetailState(
            matches: matches,
            participants: [_standing('u1')],
            pendingMatchIds: const {'M1'},
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(tester.widget(bracketRounds), same(initialRounds));

        controller.add(
          _AdminTournamentDetailState(
            matches: matches,
            participants: [_standing('u1')],
            pendingMatchIds: const {'M1', 'G1'},
            matchErrorsById: const {'G1': 'Không lưu được trận vòng bảng'},
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(tester.widget(bracketRounds), same(initialRounds));

        await controller.close();
      },
    );
  });
}
