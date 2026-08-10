import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/matches_view.dart';

class _MockBloc extends MockBloc<TournamentDetailEvent, TournamentDetailState>
    implements TournamentDetailBloc {}

class _MemberState extends TournamentDetailState {
  final bool member;
  final bool admin;

  _MemberState({
    super.league,
    super.matches,
    super.participants,
    List<GNUser> users = const [],
    super.pendingMatchIds,
    super.matchErrorsById,
    super.streamErrors,
    super.matchesSliceStatus,
    this.member = false,
    this.admin = false,
  }) : super(usersById: {for (final user in users) user.id: user});

  @override
  bool get currentUserIsMember => member;

  @override
  bool get currentUserIsLeagueAdmin => admin;
}

GNUser _user(String id, String name) {
  return GNUser(
    id: id,
    displayName: name,
    phoneNumber: null,
    email: '$id@example.com',
    photoUrl: null,
    role: 'user',
    fcmToken: '',
  );
}

GNEsportGroup _group() {
  return GNEsportGroup(
    id: 'g1',
    groupName: 'Group One',
    ownerId: 'owner',
    members: const ['owner', 'u1', 'u2'],
    description: '',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    status: 'active',
  );
}

GNEsportLeague _league() {
  return GNEsportLeague(
    id: 'l1',
    ownerId: 'owner',
    groupId: 'g1',
    name: 'League One',
    startDate: DateTime(2026, 1, 1),
    isActive: true,
    description: '',
    participants: const ['u1', 'u2'],
    group: _group(),
  );
}

GNEsportLeagueStat _stat(String userId) {
  return GNEsportLeagueStat(
    id: 's_$userId',
    userId: userId,
    leagueId: 'l1',
    matchesPlayed: 0,
    goals: 0,
    goalsConceded: 0,
    wins: 0,
    draws: 0,
    losses: 0,
    user: _user(userId, 'Player $userId'),
  );
}

GNEsportMatch _match({
  String id = 'm1',
  bool finished = false,
  String homeName = 'Alice',
  String awayName = 'Bob',
  int? matchday,
}) {
  return GNEsportMatch(
    id: id,
    homeTeamId: 'u1',
    awayTeamId: 'u2',
    homeScore: finished ? 2 : null,
    awayScore: finished ? 1 : null,
    date: DateTime(2026, 1, 1),
    isFinished: finished,
    leagueId: 'l1',
    homeTeam: _user('u1', homeName),
    awayTeam: _user('u2', awayName),
    matchday: matchday,
  );
}

Widget _wrap(TournamentDetailBloc bloc, {required bool fixtures}) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TournamentDetailBloc>.value(
      value: bloc,
      child: Scaffold(body: EsportMatchesView(isFixtures: fixtures)),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(GetParticipantsAndMatches('l1'));
    registerFallbackValue(const EnsureDetailSubscriptions('l1'));
    registerFallbackValue(
      const RetryDetailSlice(TournamentDetailSlice.matches),
    );
    registerFallbackValue(const GenerateRound());
    registerFallbackValue(DeleteEsportMatch(_match()));
    registerFallbackValue(
      CreateCustomMatch(homeTeam: _user('u1', 'A'), awayTeam: _user('u2', 'B')),
    );
  });

  testWidgets('empty state refresh returns when no league is loaded', (
    tester,
  ) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const TournamentDetailState());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc, fixtures: true));

    expect(find.text('Chưa có lịch thi đấu'), findsOneWidget);
    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await refresh.onRefresh();
    verifyNever(() => bloc.add(any()));
    await bloc.close();
  });

  testWidgets('fixtures render actions, refresh, generate and score dialog', (
    tester,
  ) async {
    final bloc = _MockBloc();
    final controller = StreamController<TournamentDetailState>.broadcast();
    final state = _MemberState(
      league: _league(),
      matches: [_match()],
      participants: [_stat('u1'), _stat('u2')],
      users: [_user('u1', 'Alice'), _user('u2', 'Bob')],
      member: true,
    );
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.stream).thenAnswer((_) => controller.stream);

    await tester.pumpWidget(_wrap(bloc, fixtures: true));

    expect(find.text('Thêm lượt đấu'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);

    await tester.tap(find.text('Thêm lượt đấu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(any(that: isA<GenerateRound>()))).called(1);

    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Cập nhật kết quả'), findsOneWidget);

    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator).first,
    );
    final future = refresh.onRefresh();
    var refreshCompleted = false;
    unawaited(future.then((_) => refreshCompleted = true));
    controller.add(state.copyWith(league: _league().copyWith(name: 'Renamed')));
    await tester.pump();
    expect(refreshCompleted, isFalse);
    controller.add(state.copyWith(refreshTick: 1));
    await future;
    expect(refreshCompleted, isTrue);
    verify(() => bloc.add(const EnsureDetailSubscriptions('l1'))).called(1);
    verifyNever(() => bloc.add(GetParticipantsAndMatches('l1')));
    await controller.close();
    await bloc.close();
  });

  testWidgets(
    'admin without membership cannot create, generate, score or delete matches',
    (tester) async {
      final fixtureBloc = _MockBloc();
      when(() => fixtureBloc.state).thenReturn(
        _MemberState(
          league: _league(),
          matches: [_match(id: 'fixture', homeName: 'Admin Fixture')],
          participants: [_stat('u1'), _stat('u2')],
          users: [_user('u1', 'Alice'), _user('u2', 'Bob')],
          member: false,
          admin: true,
        ),
      );
      when(() => fixtureBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(fixtureBloc, fixtures: true));

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.text('Thêm lượt đấu'), findsNothing);

      final fixtureSlidable = tester.widget<Slidable>(
        find.ancestor(
          of: find.text('Admin Fixture'),
          matching: find.byType(Slidable),
        ),
      );
      final fixtureDeleteActions =
          fixtureSlidable.endActionPane?.children.whereType<SlidableAction>() ??
          const <SlidableAction>[];
      expect(fixtureDeleteActions, isEmpty);

      await tester.tap(find.text('Admin Fixture'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Cập nhật kết quả'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await fixtureBloc.close();

      final resultBloc = _MockBloc();
      when(() => resultBloc.state).thenReturn(
        _MemberState(
          league: _league(),
          matches: [
            _match(id: 'result', finished: true, homeName: 'Admin Result'),
          ],
          participants: [_stat('u1'), _stat('u2')],
          member: false,
          admin: true,
        ),
      );
      when(() => resultBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(resultBloc, fixtures: false));

      final resultSlidable = tester.widget<Slidable>(
        find.ancestor(
          of: find.text('Admin Result'),
          matching: find.byType(Slidable),
        ),
      );
      final resultDeleteActions =
          resultSlidable.endActionPane?.children.whereType<SlidableAction>() ??
          const <SlidableAction>[];
      expect(resultDeleteActions, isEmpty);

      await tester.longPress(find.text('Admin Result'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Cập nhật kết quả'), findsNothing);

      await resultBloc.close();
    },
  );

  testWidgets(
    'pending and error state stay local to one match while another remains interactive',
    (tester) async {
      final bloc = _MockBloc();
      final controller = StreamController<TournamentDetailState>.broadcast();
      final matches = [
        _match(id: 'm1', homeName: 'M1 Home', awayName: 'M1 Away'),
        _match(id: 'm2', homeName: 'M2 Home', awayName: 'M2 Away'),
      ];
      final participants = [_stat('u1'), _stat('u2')];
      final pendingState = _MemberState(
        league: _league(),
        matches: matches,
        participants: participants,
        users: [_user('u1', 'Alice'), _user('u2', 'Bob')],
        pendingMatchIds: const {'m1'},
        matchErrorsById: const {'m1': 'Không lưu được M1'},
        member: true,
      );
      when(() => bloc.state).thenReturn(pendingState);
      when(() => bloc.stream).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(_wrap(bloc, fixtures: true));

      final m1Slidable = find.ancestor(
        of: find.text('M1 Home'),
        matching: find.byType(Slidable),
      );
      final m2Slidable = find.ancestor(
        of: find.text('M2 Home'),
        matching: find.byType(Slidable),
      );
      expect(m1Slidable, findsOneWidget);
      expect(m2Slidable, findsOneWidget);
      expect(find.text('Đang lưu kết quả'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Không lưu được M1'), findsNothing);

      final m1Widget = tester.widget<Slidable>(m1Slidable);
      final m2Widget = tester.widget<Slidable>(m2Slidable);
      final m1Delete =
          m1Widget.endActionPane!.children.single as SlidableAction;
      final m2Delete =
          m2Widget.endActionPane!.children.single as SlidableAction;
      expect(m1Delete.onPressed, isNull);
      expect(m2Delete.onPressed, isNotNull);

      await tester.tap(find.text('M1 Home'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Cập nhật kết quả'), findsNothing);

      await tester.tap(find.text('M2 Home'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Cập nhật kết quả'), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      controller.add(
        _MemberState(
          league: _league(),
          matches: matches,
          participants: participants,
          users: [_user('u1', 'Alice'), _user('u2', 'Bob')],
          pendingMatchIds: const {},
          matchErrorsById: const {'m1': 'Không lưu được M1'},
          member: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Đang lưu kết quả'), findsNothing);
      expect(
        find.descendant(
          of: m1Slidable,
          matching: find.text('Không lưu được M1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: m2Slidable,
          matching: find.text('Không lưu được M1'),
        ),
        findsNothing,
      );

      await controller.close();
      await bloc.close();
    },
  );

  testWidgets(
    'match-list subtree ignores league metadata but rebuilds for match snapshots',
    (tester) async {
      final bloc = _MockBloc();
      final controller = StreamController<TournamentDetailState>.broadcast();
      final matches = [_match(id: 'm1', homeName: 'Original Home')];
      final participants = [_stat('u1'), _stat('u2')];
      final initialState = _MemberState(
        league: _league(),
        matches: matches,
        participants: participants,
        member: true,
      );
      when(() => bloc.state).thenReturn(initialState);
      when(() => bloc.stream).thenAnswer((_) => controller.stream);

      await tester.pumpWidget(_wrap(bloc, fixtures: true));

      final matchList = find.byKey(const Key('tournament-match-list'));
      expect(matchList, findsOneWidget);
      final initialSubtree = tester.widget(matchList);

      controller.add(
        _MemberState(
          league: _league().copyWith(name: 'League Renamed Elsewhere'),
          matches: matches,
          participants: participants,
          member: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.widget(matchList), same(initialSubtree));

      controller.add(
        _MemberState(
          league: _league().copyWith(name: 'League Renamed Elsewhere'),
          matches: [_match(id: 'm1', homeName: 'Realtime Home')],
          participants: participants,
          member: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Original Home'), findsNothing);
      expect(find.text('Realtime Home'), findsOneWidget);

      await controller.close();
      await bloc.close();
    },
  );

  testWidgets('failed matches slice keeps rows and retries only that slice', (
    tester,
  ) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(
      _MemberState(
        league: _league(),
        matches: [_match(id: 'm1', homeName: 'Cached Home')],
        participants: [_stat('u1'), _stat('u2')],
        matchesSliceStatus: DetailSliceStatus.failed,
        streamErrors: const {
          TournamentDetailSlice.matches: 'Không thể tải trận mới',
        },
        member: true,
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc, fixtures: true));

    expect(find.text('Cached Home'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Không thể tải trận mới'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();

    verify(
      () => bloc.add(const RetryDetailSlice(TournamentDetailSlice.matches)),
    ).called(1);
    expect(find.text('Cached Home'), findsOneWidget);

    await bloc.close();
  });

  testWidgets('results search filters, clears and empty-search state appears', (
    tester,
  ) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(
      _MemberState(
        league: _league(),
        matches: [
          _match(id: 'r1', finished: true, homeName: 'Đặng A', awayName: 'Bob'),
          _match(id: 'r2', finished: true, homeName: 'Cara', awayName: 'Dan'),
        ],
        member: true,
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc, fixtures: false));

    expect(find.text('Đặng A'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'dang');
    await tester.pump();
    expect(find.text('Đặng A'), findsOneWidget);
    expect(find.text('Cara'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('Cara'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Không tìm thấy trận nào'), findsOneWidget);
    await bloc.close();
  });

  testWidgets('lịch thi đấu nhóm theo vòng', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(
      _MemberState(
        league: _league(),
        matches: [
          _match(id: 'm1', matchday: 1),
          _match(id: 'm2', matchday: 2),
        ],
        participants: [_stat('u1'), _stat('u2')],
        member: true,
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc, fixtures: true));

    expect(find.text('Vòng 1'), findsOneWidget);
    expect(find.text('Vòng 2'), findsOneWidget);
    expect(find.text('Trận khác'), findsNothing);
    await bloc.close();
  });

  testWidgets('trận không có vòng nằm dưới mục Trận khác', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(
      _MemberState(
        league: _league(),
        matches: [
          _match(id: 'm1', matchday: 1),
          _match(id: 'm2'),
        ],
        participants: [_stat('u1'), _stat('u2')],
        member: true,
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc, fixtures: true));

    expect(find.text('Vòng 1'), findsOneWidget);
    expect(find.text('Trận khác'), findsOneWidget);
    await bloc.close();
  });

  testWidgets('tab kết quả không nhóm theo vòng', (tester) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(
      _MemberState(
        league: _league(),
        matches: [_match(id: 'm1', finished: true, matchday: 1)],
        participants: [_stat('u1'), _stat('u2')],
        member: true,
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc, fixtures: false));

    expect(find.text('Vòng 1'), findsNothing);
    expect(find.text('V1'), findsOneWidget);
    await bloc.close();
  });
}
