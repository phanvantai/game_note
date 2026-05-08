import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart'; // ignore: unused_import
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/ultils.dart'; // ignore: unused_import
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/groups/group_standings_view.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockBloc
    extends MockBloc<TournamentDetailEvent, TournamentDetailState>
    implements TournamentDetailBloc {}

class _FakeTournamentDetailEvent extends Fake implements TournamentDetailEvent {}
class _FakeTournamentDetailState extends Fake implements TournamentDetailState {}

// ---------------------------------------------------------------------------
// Factories
// ---------------------------------------------------------------------------

GNUser _user(String id) => GNUser(
      id: id,
      displayName: 'Player $id',
      email: null,
      phoneNumber: null,
      photoUrl: null,
      role: 'user',
      fcmToken: '',
      isPlaceholder: false,
    );

GNEsportLeague _league({int advanceCount = 2}) => GNEsportLeague(
      id: 'L1',
      ownerId: 'owner',
      groupId: 'G1',
      name: 'Test League',
      startDate: DateTime(2026, 1, 1),
      isActive: true,
      description: '',
      participants: const [],
      advanceCount: advanceCount,
    );

GNEsportMatch _groupMatch({
  String id = 'M1',
  String groupId = 'A',
  String home = 'u1',
  String away = 'u2',
  bool isFinished = false,
  int? homeScore,
  int? awayScore,
  GNUser? homeTeam,
  GNUser? awayTeam,
}) =>
    GNEsportMatch(
      id: id,
      homeTeamId: home,
      awayTeamId: away,
      homeScore: homeScore,
      awayScore: awayScore,
      date: DateTime(2026, 1, 1),
      isFinished: isFinished,
      leagueId: 'L1',
      phase: 'group',
      groupId: groupId,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );

GNEsportLeagueStat _stat({
  String id = 'S1',
  String userId = 'u1',
  String? groupId = 'A',
  int wins = 1,
  int draws = 0,
  int losses = 0,
  int goals = 3,
  int goalsConceded = 1,
  GNUser? user,
}) =>
    GNEsportLeagueStat(
      id: id,
      userId: userId,
      leagueId: 'L1',
      matchesPlayed: wins + draws + losses,
      goals: goals,
      goalsConceded: goalsConceded,
      wins: wins,
      draws: draws,
      losses: losses,
      groupId: groupId,
      user: user,
    );

TournamentDetailState _buildState({
  GNEsportLeague? league,
  List<GNEsportLeagueStat> participants = const [],
  List<GNEsportMatch> matches = const [],
  String? selectedGroupId,
}) =>
    TournamentDetailState(
      league: league,
      participants: participants,
      matches: matches,
      selectedGroupId: selectedGroupId,
    );

Widget _wrap(_MockBloc bloc) => MaterialApp(
      home: Scaffold(
        body: BlocProvider<TournamentDetailBloc>.value(
          value: bloc,
          child: const GroupStandingsView(),
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTournamentDetailEvent());
    registerFallbackValue(_FakeTournamentDetailState());
  });

  group('GroupStandingsView', () {
    late _MockBloc bloc;

    setUp(() => bloc = _MockBloc());
    tearDown(() => bloc.close());

    testWidgets('hiện thông báo chưa có vòng bảng khi matches trống',
        (tester) async {
      when(() => bloc.state).thenReturn(_buildState());
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      expect(find.text('Chưa có vòng bảng'), findsOneWidget);
    });

    testWidgets('hiện tab bảng A và B khi có matches', (tester) async {
      final matches = [
        _groupMatch(id: 'M1', groupId: 'A'),
        _groupMatch(id: 'M2', groupId: 'B'),
      ];
      when(() => bloc.state).thenReturn(_buildState(
        league: _league(),
        matches: matches,
      ));
      when(() => bloc.add(any())).thenReturn(null);
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      expect(find.text('Bảng A'), findsOneWidget);
      expect(find.text('Bảng B'), findsOneWidget);
    });

    testWidgets('hiện tên người chơi trong bảng xếp hạng', (tester) async {
      final u1 = _user('u1');
      final u2 = _user('u2');
      final matches = [_groupMatch(id: 'M1', groupId: 'A')];
      final stats = [
        _stat(id: 'S1', userId: 'u1', groupId: 'A', wins: 1, user: u1),
        _stat(id: 'S2', userId: 'u2', groupId: 'A', wins: 0, losses: 1, user: u2),
      ];
      when(() => bloc.state).thenReturn(_buildState(
        league: _league(),
        matches: matches,
        participants: stats,
      ));
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      expect(find.text('Player u1'), findsOneWidget);
      expect(find.text('Player u2'), findsOneWidget);
    });

    testWidgets('hiện kết quả "2 – 1" cho trận đã hoàn thành', (tester) async {
      final matches = [
        _groupMatch(
          id: 'M1',
          groupId: 'A',
          isFinished: true,
          homeScore: 2,
          awayScore: 1,
          homeTeam: _user('u1'),
          awayTeam: _user('u2'),
        ),
      ];
      when(() => bloc.state).thenReturn(_buildState(
        league: _league(),
        matches: matches,
      ));
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      expect(find.text('2 – 1'), findsOneWidget);
    });

    testWidgets('hiện "vs" cho trận chưa diễn ra', (tester) async {
      final matches = [
        _groupMatch(
          id: 'M1',
          groupId: 'A',
          homeTeam: _user('u1'),
          awayTeam: _user('u2'),
        ),
      ];
      when(() => bloc.state).thenReturn(_buildState(
        league: _league(),
        matches: matches,
      ));
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      expect(find.text('vs'), findsOneWidget);
    });

    testWidgets('tap tab B gửi SelectGroup event', (tester) async {
      final matches = [
        _groupMatch(id: 'M1', groupId: 'A'),
        _groupMatch(id: 'M2', groupId: 'B'),
      ];
      when(() => bloc.state).thenReturn(_buildState(
        league: _league(),
        matches: matches,
      ));
      when(() => bloc.add(any())).thenReturn(null);
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      await tester.tap(find.text('Bảng B'));
      await tester.pump();
      verify(() => bloc.add(any(that: isA<SelectGroup>()))).called(1);
    });

    testWidgets('non-admin tap trận không mở dialog', (tester) async {
      // currentUserIsLeagueAdmin is false in tests (FirebaseAuth.currentUser = null)
      final matches = [
        _groupMatch(
          id: 'M1',
          groupId: 'A',
          homeTeam: _user('u1'),
          awayTeam: _user('u2'),
        ),
      ];
      when(() => bloc.state).thenReturn(_buildState(
        league: _league(),
        matches: matches,
      ));
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      await tester.tap(find.text('vs'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Cập nhật kết quả'), findsNothing);
    });

    testWidgets('hiện tất cả participants trong group khi advanceCount < tổng',
        (tester) async {
      final stats = [
        _stat(id: 'S1', userId: 'u1', groupId: 'A', wins: 2, user: _user('u1')),
        _stat(id: 'S2', userId: 'u2', groupId: 'A', wins: 1, user: _user('u2')),
        _stat(id: 'S3', userId: 'u3', groupId: 'A', wins: 0, user: _user('u3')),
      ];
      final matches = [_groupMatch(id: 'M1', groupId: 'A')];
      when(() => bloc.state).thenReturn(_buildState(
        league: _league(advanceCount: 2),
        matches: matches,
        participants: stats,
      ));
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      expect(find.text('Player u1'), findsOneWidget);
      expect(find.text('Player u3'), findsOneWidget);
    });

    testWidgets('header hiện đúng cột W D L GD Pts', (tester) async {
      final matches = [_groupMatch(id: 'M1', groupId: 'A')];
      when(() => bloc.state).thenReturn(_buildState(
        league: _league(),
        matches: matches,
      ));
      when(() => bloc.add(any())).thenReturn(null);
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      for (final label in ['W', 'D', 'L', 'GD', 'Pts']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('non-admin không thấy nút Thêm vòng', (tester) async {
      // currentUserIsLeagueAdmin = false khi Firebase không init
      final matches = [_groupMatch(id: 'M1', groupId: 'A')];
      when(() => bloc.state).thenReturn(_buildState(
        league: _league(),
        matches: matches,
      ));
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      expect(find.text('Thêm vòng'), findsNothing);
    });

    testWidgets('non-admin không thấy nút Thêm vòng khi có matches', (tester) async {
      final matches = [_groupMatch(id: 'M1', groupId: 'A')];
      when(() => bloc.state).thenReturn(_buildState(
        league: _league(),
        matches: matches,
      ));
      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();
      // Admin = false in test env (no Firebase) → button hidden
      expect(find.text('Thêm vòng'), findsNothing);
    });
  });

  group('TournamentDetailState.allGroupMatchesFinished', () {
    test('false khi không có group matches', () {
      const state = TournamentDetailState();
      expect(state.allGroupMatchesFinished, false);
    });

    test('false khi có group match chưa xong', () {
      final state = TournamentDetailState(
        matches: [
          _groupMatch(id: 'M1', groupId: 'A', isFinished: true),
          _groupMatch(id: 'M2', groupId: 'A', isFinished: false),
        ],
      );
      expect(state.allGroupMatchesFinished, false);
    });

    test('true khi tất cả group matches đã xong', () {
      final state = TournamentDetailState(
        matches: [
          _groupMatch(id: 'M1', groupId: 'A', isFinished: true),
          _groupMatch(id: 'M2', groupId: 'A', isFinished: true),
        ],
      );
      expect(state.allGroupMatchesFinished, true);
    });

    test('knockout-only matches không tính vào group matches', () {
      final state = TournamentDetailState(
        matches: [
          GNEsportMatch(
            id: 'K1',
            homeTeamId: 'u1',
            awayTeamId: 'u2',
            date: DateTime(2026),
            isFinished: false,
            leagueId: 'L1',
            phase: 'knockout',
            knockoutRound: 0,
            knockoutSlot: 0,
          ),
        ],
      );
      // no group matches → false
      expect(state.allGroupMatchesFinished, false);
    });
  });
}
