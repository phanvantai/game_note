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
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/table/table_view.dart';

class _MockBloc extends MockBloc<TournamentDetailEvent, TournamentDetailState>
    implements TournamentDetailBloc {}

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

GNEsportLeague _league({String name = 'League One', DateTime? endDate}) {
  return GNEsportLeague(
    id: 'l1',
    ownerId: 'owner',
    groupId: 'g1',
    name: name,
    startDate: DateTime(2026, 1, 1),
    endDate: endDate,
    isActive: true,
    description: '',
    participants: const ['u1', 'u2', 'u3', 'u4'],
    group: _group(),
  );
}

GNEsportLeagueStat _stat({
  required String userId,
  required String name,
  int wins = 0,
  int draws = 0,
  int losses = 0,
  int goals = 0,
  int goalsConceded = 0,
}) {
  return GNEsportLeagueStat(
    id: 's_$userId',
    userId: userId,
    leagueId: 'l1',
    matchesPlayed: wins + draws + losses,
    goals: goals,
    goalsConceded: goalsConceded,
    wins: wins,
    draws: draws,
    losses: losses,
    user: _user(userId, name),
  );
}

GNEsportMatch _match(String id) {
  return GNEsportMatch(
    id: id,
    homeTeamId: 'u1',
    awayTeamId: 'u2',
    homeScore: 2,
    awayScore: 1,
    date: DateTime(2026, 1, 1),
    isFinished: true,
    leagueId: 'l1',
  );
}

Widget _wrap(TournamentDetailBloc bloc) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TournamentDetailBloc>.value(
      value: bloc,
      child: const Scaffold(body: EsportTableView()),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(GetParticipantsAndMatches('l1'));
  });

  testWidgets('renders empty state and refresh returns when league is null', (
    tester,
  ) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(const TournamentDetailState());
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('Chưa có người chơi nào'), findsOneWidget);
    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await refresh.onRefresh();
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('renders standings table, metric summary, and refresh event', (
    tester,
  ) async {
    final bloc = _MockBloc();
    final controller = StreamController<TournamentDetailState>.broadcast();
    final state = TournamentDetailState(
      league: _league(endDate: DateTime(2026, 1, 31)),
      participants: [
        _stat(userId: 'u1', name: 'Alice', wins: 3, goals: 9, goalsConceded: 1),
        _stat(userId: 'u2', name: 'Bob', wins: 2, draws: 1, goals: 6),
        _stat(userId: 'u3', name: 'Cara', wins: 1, losses: 2),
        _stat(userId: 'u4', name: 'Dan', losses: 3),
      ],
      matches: [_match('m1'), _match('m2')],
    );
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.stream).thenAnswer((_) => controller.stream);

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Cara'), findsOneWidget);
    expect(find.text('Dan'), findsOneWidget);
    expect(find.text('4'), findsAtLeastNWidgets(1));
    expect(find.text('2'), findsAtLeastNWidgets(1));

    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    final future = refresh.onRefresh();
    controller.add(state.copyWith(refreshTick: 1));
    await future;
    verify(
      () => bloc.add(any(that: isA<GetParticipantsAndMatches>())),
    ).called(1);
    await controller.close();
  });

  testWidgets('metric summary uses single-date format without end date', (
    tester,
  ) async {
    final bloc = _MockBloc();
    when(() => bloc.state).thenReturn(
      TournamentDetailState(
        league: _league(),
        participants: [_stat(userId: 'u1', name: 'Alice')],
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('01/01/2026'), findsOneWidget);
    await bloc.close();
  });
}
