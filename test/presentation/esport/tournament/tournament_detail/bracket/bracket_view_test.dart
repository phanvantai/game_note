import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bracket/bracket_view.dart';

class _MockBloc extends MockBloc<TournamentDetailEvent, TournamentDetailState>
    implements TournamentDetailBloc {}

class _AdminTournamentDetailState extends TournamentDetailState {
  const _AdminTournamentDetailState({required super.matches});

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
  });
}
