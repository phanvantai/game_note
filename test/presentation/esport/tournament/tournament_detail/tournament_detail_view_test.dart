import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/table/table_view.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/tournament_detail_view.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/widgets/league_share_card.dart';

class _MockBloc extends MockBloc<TournamentDetailEvent, TournamentDetailState>
    implements TournamentDetailBloc {}

class _MockRemoteConfig extends Mock implements GNRemoteConfig {}

class _DetailState extends TournamentDetailState {
  final bool member;
  final bool admin;

  _DetailState({
    super.viewStatus,
    super.statsSliceStatus = DetailSliceStatus.ready,
    super.matchesSliceStatus = DetailSliceStatus.ready,
    super.league,
    super.participants,
    super.matches,
    super.pendingMatchIds,
    super.streamErrors,
    List<GNUser> users = const [],
    this.member = false,
    this.admin = false,
  }) : super(
         leagueSliceStatus: DetailSliceStatus.ready,
         usersById: {for (final user in users) user.id: user},
       );

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

GNEsportLeague _league({
  String id = 'l1',
  String name = 'League One',
  TournamentMode mode = TournamentMode.league,
  String status = 'ongoing',
  bool rankPayoutEnabled = false,
  List<int> rankPayouts = const [],
}) {
  return GNEsportLeague(
    id: id,
    ownerId: 'owner',
    groupId: 'g1',
    name: name,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 1, 31),
    isActive: true,
    description: '',
    participants: const ['u1', 'u2'],
    status: status,
    group: _group(),
    mode: mode,
    rankPayoutEnabled: rankPayoutEnabled,
    rankPayouts: rankPayouts,
  );
}

GNEsportLeagueStat _stat(String userId, String name, int wins) {
  return GNEsportLeagueStat(
    id: 's_$userId',
    userId: userId,
    leagueId: 'l1',
    matchesPlayed: 1,
    goals: wins + 1,
    goalsConceded: 0,
    wins: wins,
    draws: 0,
    losses: 0,
    user: _user(userId, name),
  );
}

GNEsportMatch _match({
  String id = 'm1',
  bool finished = true,
  String? phase,
  int? matchCost,
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
    phase: phase,
    matchCost: matchCost,
    homeTeam: _user('u1', 'Alice'),
    awayTeam: _user('u2', 'Bob'),
  );
}

Widget _wrap(TournamentDetailBloc bloc) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<TournamentDetailBloc>.value(
      value: bloc,
      child: const TournamentDetailView(),
    ),
  );
}

StreamController<TournamentDetailState> _stubStateStream(
  _MockBloc bloc,
  TournamentDetailState initialState,
) {
  final controller = StreamController<TournamentDetailState>();
  whenListen(bloc, controller.stream, initialState: initialState);
  return controller;
}

Future<void> _emitState(
  WidgetTester tester,
  StreamController<TournamentDetailState> controller,
  TournamentDetailState state,
) async {
  controller.add(state);
  await tester.pump();
}

Future<void> _pumpTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxFrames = 20,
}) async {
  for (var frame = 0; frame < maxFrames && finder.evaluate().isEmpty; frame++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _selectShare(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_horiz));
  await _pumpTransition(tester);
  await tester.tap(find.text('Chia sẻ BXH').last);
  await tester.pump();
}

void main() {
  late _MockBloc bloc;
  late _MockRemoteConfig remoteConfig;

  setUpAll(() {
    registerFallbackValue(ChangeLeagueStatus(GNEsportLeagueStatus.ongoing));
    registerFallbackValue(const EnsureDetailSubscriptions('l1'));
    registerFallbackValue(const GenerateRound());
    registerFallbackValue(RecomputeStats());
    registerFallbackValue(InactiveLeague());
    registerFallbackValue(SubmitLeagueStatus());
  });

  setUp(() {
    bloc = _MockBloc();
    remoteConfig = _MockRemoteConfig();
    when(() => remoteConfig.adsEnabled).thenReturn(false);
    if (GetIt.instance.isRegistered<GNRemoteConfig>()) {
      GetIt.instance.unregister<GNRemoteConfig>();
    }
    GetIt.instance.registerSingleton<GNRemoteConfig>(remoteConfig);
  });

  tearDown(() async {
    await bloc.close();
    if (GetIt.instance.isRegistered<GNRemoteConfig>()) {
      GetIt.instance.unregister<GNRemoteConfig>();
    }
  });

  testWidgets(
    'renders league mode hero, tabs, bootstrap loading and add dialog',
    (tester) async {
      final state = _DetailState(
        viewStatus: ViewStatus.initial,
        statsSliceStatus: DetailSliceStatus.waiting,
        matchesSliceStatus: DetailSliceStatus.waiting,
        league: _league(name: ''),
        participants: [_stat('u1', 'Alice', 2), _stat('u2', 'Bob', 1)],
        matches: [
          _match(finished: false),
          _match(id: 'm2'),
        ],
        users: [_user('u1', 'Alice'), _user('u2', 'Bob')],
        member: true,
        admin: true,
      );
      when(() => bloc.state).thenReturn(state);
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(bloc));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('tournament-detail-shell')), findsOneWidget);
      expect(find.textContaining('Group One'), findsWidgets);
      expect(find.text('BXH'), findsOneWidget);
      expect(find.text('Lịch'), findsOneWidget);
      expect(find.text('Kết quả'), findsOneWidget);
      expect(find.text('Chi phí'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
    },
  );

  testWidgets('admin menu changes status, recomputes and deletes', (
    tester,
  ) async {
    final state = _DetailState(
      league: _league(),
      participants: [_stat('u1', 'Alice', 2), _stat('u2', 'Bob', 1)],
      matches: [_match()],
      member: true,
      admin: true,
    );
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    await tester.tap(find.byIcon(Icons.more_horiz));
    await _pumpTransition(tester);
    await tester.tap(find.text('Trạng thái').last);
    await _pumpTransition(tester);
    await tester.tap(find.text('Lưu'));
    await _pumpTransition(tester);
    verify(() => bloc.add(any(that: isA<SubmitLeagueStatus>()))).called(1);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await _pumpTransition(tester);
    await tester.tap(find.text('Đồng bộ điểm số'));
    await _pumpTransition(tester);
    await tester.tap(find.text('Đồng bộ'));
    await _pumpTransition(tester);
    verify(() => bloc.add(any(that: isA<RecomputeStats>()))).called(1);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await _pumpTransition(tester);
    await tester.tap(find.text('Xóa giải đấu'));
    await _pumpTransition(tester);
    await tester.tap(find.text('Xoá'));
    await _pumpTransition(tester);
    verify(() => bloc.add(any(that: isA<InactiveLeague>()))).called(1);
  });

  testWidgets('renders cup and full mode tab sets', (tester) async {
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => bloc.state,
    ).thenReturn(_DetailState(league: _league(mode: TournamentMode.cup)));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('Bracket'), findsOneWidget);
    expect(find.text('Kết quả'), findsOneWidget);
    expect(find.text('Chi phí'), findsOneWidget);

    await bloc.close();
    bloc = _MockBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => bloc.state,
    ).thenReturn(_DetailState(league: _league(mode: TournamentMode.full)));
    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();
    expect(find.text('Bảng'), findsWidgets);
    expect(find.text('Bracket'), findsOneWidget);
  });

  testWidgets(
    'lifecycle resume ensures subscriptions without legacy aggregate refresh',
    (tester) async {
      when(
        () => bloc.state,
      ).thenReturn(_DetailState(league: _league(id: 'L1')));
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(_wrap(bloc));
      clearInteractions(bloc);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      final capturedEvents = verify(() => bloc.add(captureAny())).captured;
      expect(capturedEvents, [const EnsureDetailSubscriptions('L1')]);
    },
  );

  testWidgets(
    'score and standings updates preserve shell and header widget identity',
    (tester) async {
      final initial = _DetailState(
        league: _league(),
        participants: [_stat('u1', 'Alice', 1), _stat('u2', 'Bob', 0)],
        matches: [_match()],
      );
      final states = _stubStateStream(bloc, initial);
      addTearDown(states.close);

      await tester.pumpWidget(_wrap(bloc));
      final shellFinder = find.byKey(const Key('tournament-detail-shell'));
      final headerFinder = find.byKey(const Key('tournament-detail-header'));
      expect(shellFinder, findsOneWidget);
      expect(headerFinder, findsOneWidget);
      final shellBefore = tester.widget(shellFinder);
      final headerBefore = tester.widget(headerFinder);

      await _emitState(
        tester,
        states,
        _DetailState(
          league: _league(),
          participants: [_stat('u1', 'Alice', 4), _stat('u2', 'Bob', 2)],
          matches: [_match(id: 'm2')],
        ),
      );

      expect(tester.widget(shellFinder), same(shellBefore));
      expect(tester.widget(headerFinder), same(headerBefore));
    },
  );

  testWidgets('league name updates header while preserving standings subtree', (
    tester,
  ) async {
    final initial = _DetailState(
      league: _league(name: 'League One'),
      participants: [_stat('u1', 'Alice', 1), _stat('u2', 'Bob', 0)],
    );
    final states = _stubStateStream(bloc, initial);
    addTearDown(states.close);

    await tester.pumpWidget(_wrap(bloc));
    final headerFinder = find.byKey(const Key('tournament-detail-header'));
    expect(headerFinder, findsOneWidget);
    final standingsBefore = tester.element(find.byType(EsportTableView));
    expect(
      find.descendant(of: headerFinder, matching: find.text('League One')),
      findsOneWidget,
    );

    await _emitState(
      tester,
      states,
      _DetailState(
        league: _league(name: 'League Renamed'),
        participants: initial.participants,
      ),
    );

    expect(
      find.descendant(of: headerFinder, matching: find.text('League One')),
      findsNothing,
    );
    expect(
      find.descendant(of: headerFinder, matching: find.text('League Renamed')),
      findsOneWidget,
    );
    expect(tester.element(find.byType(EsportTableView)), same(standingsBefore));
  });

  testWidgets('share cards and capture layer are absent before share', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      _DetailState(
        league: _league(),
        participants: [_stat('u1', 'Alice', 1), _stat('u2', 'Bob', 0)],
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.byType(LeagueShareCard), findsNothing);
    expect(find.byKey(const Key('tournament-share-layer')), findsNothing);
  });

  testWidgets(
    'share layer uses immutable required variants and cleans up on close',
    (tester) async {
      final initial = _DetailState(
        league: _league(name: 'Captured League'),
        participants: [_stat('u1', 'Alice', 1), _stat('u2', 'Bob', 0)],
        matches: [_match(matchCost: 0)],
      );
      final states = _stubStateStream(bloc, initial);
      addTearDown(states.close);

      await tester.pumpWidget(_wrap(bloc));
      await _selectShare(tester);

      expect(find.byKey(const Key('tournament-share-layer')), findsOneWidget);
      expect(find.byType(LeagueShareCard), findsNWidgets(2));
      final cardsBefore = tester
          .widgetList<LeagueShareCard>(find.byType(LeagueShareCard))
          .toList();
      expect(
        cardsBefore.map((card) => card.isDark),
        containsAll([true, false]),
      );
      expect(cardsBefore.every((card) => !card.includeRankCost), isTrue);
      expect(
        cardsBefore.every((card) => card.leagueName == 'Captured League'),
        isTrue,
      );

      await _emitState(
        tester,
        states,
        _DetailState(
          league: _league(
            name: 'Realtime Rename',
            rankPayoutEnabled: true,
            rankPayouts: const [100, 50],
          ),
          participants: [_stat('u1', 'Alice Updated', 9)],
          matches: [_match(matchCost: 100)],
        ),
      );

      final cardsAfter = tester
          .widgetList<LeagueShareCard>(find.byType(LeagueShareCard))
          .toList();
      expect(cardsAfter, hasLength(2));
      expect(cardsAfter[0], same(cardsBefore[0]));
      expect(cardsAfter[1], same(cardsBefore[1]));
      expect(
        cardsAfter.every((card) => card.leagueName == 'Captured League'),
        isTrue,
      );
      expect(cardsAfter.every((card) => card.participants.length == 2), isTrue);
      expect(cardsAfter.every((card) => !card.includeRankCost), isTrue);

      final closeButton = find.widgetWithText(OutlinedButton, 'Đóng');
      await _pumpUntilFound(tester, closeButton);
      expect(find.text('Chia sẻ bảng xếp hạng'), findsOneWidget);
      tester.widget<OutlinedButton>(closeButton).onPressed!();
      await _pumpTransition(tester);
      await tester.pump();

      expect(find.byType(LeagueShareCard), findsNothing);
      expect(find.byKey(const Key('tournament-share-layer')), findsNothing);
    },
  );

  testWidgets('share layer adds cost variants only when required', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      _DetailState(
        league: _league(rankPayoutEnabled: true, rankPayouts: const [100, 50]),
        participants: [_stat('u1', 'Alice', 1), _stat('u2', 'Bob', 0)],
        matches: [_match(matchCost: 100)],
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));
    await _selectShare(tester);

    final cards = tester
        .widgetList<LeagueShareCard>(find.byType(LeagueShareCard))
        .toList();
    expect(cards, hasLength(4));
    expect(cards.where((card) => card.includeRankCost), hasLength(2));
    expect(cards.where((card) => !card.includeRankCost), hasLength(2));
    expect(cards.map((card) => (card.isDark, card.includeRankCost)).toSet(), {
      (true, false),
      (false, false),
      (true, true),
      (false, true),
    });

    final closeButton = find.widgetWithText(OutlinedButton, 'Đóng');
    await _pumpUntilFound(tester, closeButton);
    expect(closeButton, findsOneWidget);
    expect(find.byKey(const Key('tournament-share-layer')), findsOneWidget);
    tester.widget<OutlinedButton>(closeButton).onPressed!();
    await _pumpTransition(tester);
    await tester.pump();
  });

  testWidgets(
    'cached matches survive slice error with retry and no global feedback',
    (tester) async {
      final cachedMatch = _match(finished: false);
      final initial = _DetailState(
        league: _league(),
        participants: [_stat('u1', 'Alice', 1), _stat('u2', 'Bob', 0)],
        matches: [cachedMatch],
      );
      final states = _stubStateStream(bloc, initial);
      addTearDown(states.close);

      await tester.pumpWidget(_wrap(bloc));
      await tester.tap(find.text('Lịch'));
      await _pumpTransition(tester);
      expect(find.byKey(const Key('tournament-match-list')), findsOneWidget);

      await _emitState(
        tester,
        states,
        _DetailState(
          league: _league(),
          participants: initial.participants,
          matches: [cachedMatch],
          matchesSliceStatus: DetailSliceStatus.failed,
          streamErrors: const {
            TournamentDetailSlice.matches: 'Mất kết nối lịch đấu',
          },
        ),
      );

      expect(find.byKey(const Key('tournament-match-list')), findsOneWidget);
      expect(find.text('Mất kết nối lịch đấu'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Thử lại'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(MaterialBanner), findsNothing);

      await tester.tap(find.widgetWithText(TextButton, 'Thử lại'));
      verify(
        () => bloc.add(const RetryDetailSlice(TournamentDetailSlice.matches)),
      ).called(1);
      expect(find.byKey(const Key('tournament-detail-shell')), findsOneWidget);
    },
  );

  testWidgets('local pending match does not show page-global progress', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      _DetailState(
        league: _league(),
        participants: [_stat('u1', 'Alice', 1), _stat('u2', 'Bob', 0)],
        matches: [_match(finished: false)],
        pendingMatchIds: const {'m1'},
      ),
    );
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(_wrap(bloc));

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
