import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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

  const _MemberState({
    super.league,
    super.matches,
    super.participants,
    super.users,
    this.member = false,
  });

  @override
  bool get currentUserIsMember => member;
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
    controller.add(state.copyWith(refreshTick: 1));
    await future;
    verify(
      () => bloc.add(any(that: isA<GetParticipantsAndMatches>())),
    ).called(1);
    await controller.close();
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
        matches: [_match(id: 'm1', matchday: 1), _match(id: 'm2')],
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
