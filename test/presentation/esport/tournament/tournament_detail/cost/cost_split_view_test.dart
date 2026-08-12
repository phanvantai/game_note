import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/cost/cost_split_view.dart';

class _MockBloc extends MockBloc<TournamentDetailEvent, TournamentDetailState>
    implements TournamentDetailBloc {}

class _CostState extends TournamentDetailState {
  const _CostState({
    required super.league,
    super.participants,
    super.matches,
    super.statsSliceStatus = DetailSliceStatus.ready,
    super.matchesSliceStatus = DetailSliceStatus.ready,
    super.streamErrors,
    super.refreshTick,
  });

  @override
  bool get currentUserIsLeagueAdmin => false;
}

GNUser _user(String id, String name) {
  return GNUser(
    id: id,
    displayName: name,
    phoneNumber: null,
    email: '$id@example.com',
    photoUrl: null,
    role: 'user',
  );
}

GNEsportLeagueStat _stat(
  String userId,
  String name, {
  int wins = 0,
  int draws = 0,
  int losses = 0,
}) {
  return GNEsportLeagueStat(
    id: 's_$userId',
    userId: userId,
    leagueId: 'l1',
    matchesPlayed: wins + draws + losses,
    goals: 0,
    goalsConceded: 0,
    wins: wins,
    draws: draws,
    losses: losses,
    user: _user(userId, name),
  );
}

GNEsportLeague _league({
  String name = 'League One',
  String status = 'ongoing',
  bool rankPayoutEnabled = true,
  List<int> rankPayouts = const [50000],
  int defaultMatchCost = 0,
  bool defaultPerGoalEnabled = false,
  int defaultCostPerGoal = 0,
}) {
  return GNEsportLeague(
    id: 'l1',
    ownerId: 'owner',
    groupId: 'g1',
    name: name,
    startDate: DateTime(2026, 1, 1),
    isActive: true,
    description: '',
    participants: const ['a', 'b', 'c'],
    status: status,
    rankPayoutEnabled: rankPayoutEnabled,
    rankPayouts: rankPayouts,
    defaultMatchCost: defaultMatchCost,
    defaultPerGoalEnabled: defaultPerGoalEnabled,
    defaultCostPerGoal: defaultCostPerGoal,
  );
}

GNEsportMatch _finishedMatch({required String id, required int matchCost}) {
  return GNEsportMatch(
    id: id,
    homeTeamId: 'a',
    awayTeamId: 'b',
    homeScore: 2,
    awayScore: 0,
    date: DateTime(2026, 1, 2),
    isFinished: true,
    leagueId: 'l1',
    matchCost: matchCost,
  );
}

Widget _wrap(TournamentDetailBloc bloc) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TournamentDetailBloc>.value(
      value: bloc,
      child: const Scaffold(body: CostSplitView()),
    ),
  );
}

StreamController<TournamentDetailState> _stubStateStream(
  _MockBloc bloc,
  TournamentDetailState initial,
) {
  final controller = StreamController<TournamentDetailState>.broadcast();
  when(() => bloc.state).thenReturn(initial);
  when(() => bloc.stream).thenAnswer((_) => controller.stream);
  return controller;
}

Future<void> _emitState(
  WidgetTester tester,
  StreamController<TournamentDetailState> controller,
  TournamentDetailState state,
) async {
  controller.add(state);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

Widget _keyedCostContent(WidgetTester tester) {
  final content = find.byKey(const Key('league-cost-content'));
  expect(
    content,
    findsOneWidget,
    reason: 'The cost body must expose its stable selector boundary.',
  );
  return tester.widget(content);
}

Finder _rowContaining(String text) {
  return find.ancestor(of: find.text(text), matching: find.byType(Row));
}

void main() {
  setUpAll(() {
    registerFallbackValue(const EnsureDetailSubscriptions('l1'));
    registerFallbackValue(const RetryDetailSlice(TournamentDetailSlice.stats));
  });

  testWidgets('league name preserves the exact cost content widget', (
    tester,
  ) async {
    final bloc = _MockBloc();
    final initial = _CostState(
      league: _league(),
      participants: [_stat('a', 'Alice', wins: 2), _stat('b', 'Bob')],
    );
    final states = _stubStateStream(bloc, initial);
    addTearDown(states.close);
    addTearDown(bloc.close);

    await tester.pumpWidget(_wrap(bloc));
    final contentBefore = _keyedCostContent(tester);
    expect(find.text('+50k'), findsOneWidget);

    await _emitState(
      tester,
      states,
      _CostState(
        league: _league(name: 'Renamed League'),
        participants: initial.participants,
      ),
    );

    expect(_keyedCostContent(tester), same(contentBefore));
    expect(find.text('+50k'), findsOneWidget);
  });

  testWidgets(
    'status-only league snapshot rebuilds cost content and removes estimated label',
    (tester) async {
      final bloc = _MockBloc();
      final participants = [_stat('a', 'Alice', wins: 2), _stat('b', 'Bob')];
      final initial = _CostState(
        league: _league(status: 'ongoing'),
        participants: participants,
      );
      final states = _stubStateStream(bloc, initial);
      addTearDown(states.close);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(bloc));
      final contentBefore = _keyedCostContent(tester);
      expect(find.text('(tạm tính)'), findsOneWidget);

      await _emitState(
        tester,
        states,
        _CostState(
          league: _league(status: 'finished'),
          participants: participants,
        ),
      );

      expect(_keyedCostContent(tester), isNot(same(contentBefore)));
      expect(find.text('(tạm tính)'), findsNothing);
    },
  );

  testWidgets('cost configuration recomputes the keyed cost body', (
    tester,
  ) async {
    final bloc = _MockBloc();
    final participants = [_stat('a', 'Alice', wins: 2), _stat('b', 'Bob')];
    final initial = _CostState(
      league: _league(rankPayouts: const [50000]),
      participants: participants,
    );
    final states = _stubStateStream(bloc, initial);
    addTearDown(states.close);
    addTearDown(bloc.close);

    await tester.pumpWidget(_wrap(bloc));
    final contentBefore = _keyedCostContent(tester);
    expect(find.text('50k'), findsOneWidget);

    await _emitState(
      tester,
      states,
      _CostState(
        league: _league(rankPayouts: const [80000]),
        participants: participants,
      ),
    );

    expect(_keyedCostContent(tester), isNot(same(contentBefore)));
    expect(find.text('50k'), findsNothing);
    expect(find.text('80k'), findsOneWidget);
  });

  testWidgets('relevant stats recompute the keyed cost body and net output', (
    tester,
  ) async {
    final bloc = _MockBloc();
    final initial = _CostState(
      league: _league(rankPayouts: const [50000, 100000]),
      participants: [
        _stat('a', 'Alice', wins: 3),
        _stat('b', 'Bob', wins: 2),
        _stat('c', 'Cara'),
      ],
    );
    final states = _stubStateStream(bloc, initial);
    addTearDown(states.close);
    addTearDown(bloc.close);

    await tester.pumpWidget(_wrap(bloc));
    final contentBefore = _keyedCostContent(tester);
    expect(
      find.descendant(
        of: _rowContaining('+150k'),
        matching: find.text('Alice'),
      ),
      findsOneWidget,
    );

    await _emitState(
      tester,
      states,
      _CostState(
        league: initial.league,
        participants: [
          _stat('c', 'Cara', wins: 4),
          _stat('a', 'Alice', wins: 3),
          _stat('b', 'Bob'),
        ],
      ),
    );

    expect(_keyedCostContent(tester), isNot(same(contentBefore)));
    expect(
      find.descendant(of: _rowContaining('+150k'), matching: find.text('Cara')),
      findsOneWidget,
    );
  });

  testWidgets(
    'relevant finished match recomputes the keyed cost body and match output',
    (tester) async {
      final bloc = _MockBloc();
      final participants = [_stat('a', 'Alice'), _stat('b', 'Bob')];
      final initial = _CostState(
        league: _league(rankPayoutEnabled: false, rankPayouts: const []),
        participants: participants,
        matches: [_finishedMatch(id: 'm1', matchCost: 50000)],
      );
      final states = _stubStateStream(bloc, initial);
      addTearDown(states.close);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(bloc));
      final contentBefore = _keyedCostContent(tester);
      expect(find.text('50k'), findsOneWidget);

      await _emitState(
        tester,
        states,
        _CostState(
          league: initial.league,
          participants: participants,
          matches: [_finishedMatch(id: 'm1', matchCost: 80000)],
        ),
      );

      expect(_keyedCostContent(tester), isNot(same(contentBefore)));
      expect(find.text('50k'), findsNothing);
      expect(find.text('80k'), findsOneWidget);
    },
  );

  testWidgets(
    'pull refresh ensures active subscriptions only and waits for refresh tick',
    (tester) async {
      final bloc = _MockBloc();
      final initial = _CostState(
        league: _league(),
        participants: [_stat('a', 'Alice', wins: 1), _stat('b', 'Bob')],
      );
      final states = _stubStateStream(bloc, initial);
      addTearDown(states.close);
      addTearDown(bloc.close);

      await tester.pumpWidget(_wrap(bloc));
      final refresh = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      var completed = false;
      final refreshFuture = refresh.onRefresh();
      unawaited(refreshFuture.then((_) => completed = true));

      await _emitState(
        tester,
        states,
        _CostState(
          league: _league(name: 'Unrelated rename'),
          participants: initial.participants,
        ),
      );
      expect(completed, isFalse);

      await _emitState(
        tester,
        states,
        _CostState(
          league: initial.league,
          participants: initial.participants,
          refreshTick: 1,
        ),
      );
      await refreshFuture;

      final events = verify(() => bloc.add(captureAny())).captured;
      expect(events, hasLength(1));
      expect(events.single.runtimeType, EnsureDetailSubscriptions);
      expect((events.single as EnsureDetailSubscriptions).leagueId, 'l1');
    },
  );

  for (final slice in [
    TournamentDetailSlice.stats,
    TournamentDetailSlice.matches,
  ]) {
    testWidgets(
      '$slice error keeps confirmed cost summary and retries only that slice',
      (tester) async {
        final bloc = _MockBloc();
        final initial = _CostState(
          league: _league(),
          participants: [_stat('a', 'Alice', wins: 2), _stat('b', 'Bob')],
        );
        final states = _stubStateStream(bloc, initial);
        addTearDown(states.close);
        addTearDown(bloc.close);

        await tester.pumpWidget(_wrap(bloc));
        expect(find.text('+50k'), findsOneWidget);

        await _emitState(
          tester,
          states,
          _CostState(
            league: initial.league,
            participants: initial.participants,
            statsSliceStatus: slice == TournamentDetailSlice.stats
                ? DetailSliceStatus.failed
                : DetailSliceStatus.ready,
            matchesSliceStatus: slice == TournamentDetailSlice.matches
                ? DetailSliceStatus.failed
                : DetailSliceStatus.ready,
            streamErrors: {slice: 'Mất kết nối dữ liệu chi phí'},
          ),
        );

        expect(find.byKey(const Key('league-cost-content')), findsOneWidget);
        expect(find.text('+50k'), findsOneWidget);
        expect(find.text('Mất kết nối dữ liệu chi phí'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Thử lại'), findsOneWidget);
        expect(find.byType(AppEmptyState), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);

        await tester.tap(find.widgetWithText(TextButton, 'Thử lại'));
        await tester.pump();

        verify(() => bloc.add(RetryDetailSlice(slice))).called(1);
        expect(find.text('+50k'), findsOneWidget);
      },
    );
  }
}
