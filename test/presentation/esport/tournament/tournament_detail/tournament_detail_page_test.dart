import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/tournament_detail_page.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/tournament_detail_view.dart';

class _MockLeagueRepository extends Mock implements EsportLeagueRepository {}

class _MockGroupRepository extends Mock implements EsportGroupRepository {}

class _MockRemoteConfig extends Mock implements GNRemoteConfig {}

class _DetailStreams {
  final league = StreamController<GNEsportLeague?>.broadcast();
  final stats = StreamController<List<GNEsportLeagueStat>>.broadcast();
  final matches = StreamController<List<GNEsportMatch>>.broadcast();

  Future<void> close() async {
    await league.close();
    await stats.close();
    await matches.close();
  }
}

const _openDetailKey = Key('open-league-detail');
const _markerKey = Key('league-list-marker');

GNEsportGroup _group() {
  final now = DateTime(2026, 8, 10);
  return GNEsportGroup(
    id: 'G1',
    groupName: 'Group One',
    ownerId: 'owner',
    members: const ['owner'],
    description: '',
    createdAt: now,
    updatedAt: now,
    status: 'active',
  );
}

GNEsportLeague _league({required bool isActive}) {
  return GNEsportLeague(
    id: 'L1',
    ownerId: 'owner',
    groupId: 'G1',
    name: 'League One',
    startDate: DateTime(2026, 8, 10),
    isActive: isActive,
    description: '',
    participants: const [],
    group: _group(),
    status: GNEsportLeagueStatus.ongoing.value,
  );
}

Widget _app() {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text('League list', key: _markerKey),
              FilledButton(
                key: _openDetailKey,
                onPressed: () => context.push('/league/L1'),
                child: const Text('Open detail'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/league/:leagueId',
        builder: (context, state) =>
            TournamentDetailPage(leagueId: state.pathParameters['leagueId']!),
      ),
    ],
  );

  return MaterialApp.router(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

Future<void> _openDetail(WidgetTester tester, _DetailStreams streams) async {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(_app());
  await tester.tap(find.byKey(_openDetailKey));
  await tester.pump();
  await _pumpUntil(
    tester,
    () =>
        find.byType(TournamentDetailPage).evaluate().isNotEmpty &&
        streams.league.hasListener &&
        streams.stats.hasListener &&
        streams.matches.hasListener,
  );
  expect(streams.league.hasListener, isTrue);
  expect(streams.stats.hasListener, isTrue);
  expect(streams.matches.hasListener, isTrue);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxPumps = 60,
}) async {
  for (var i = 0; i < maxPumps && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Future<void> _waitForDetailToClose(WidgetTester tester) async {
  await _pumpUntil(
    tester,
    () =>
        find.byType(TournamentDetailPage).evaluate().isEmpty &&
        find.byKey(_markerKey).evaluate().isNotEmpty,
  );
  if (find.byType(TournamentDetailPage).evaluate().isNotEmpty ||
      find.byKey(_markerKey).evaluate().isEmpty) {
    throw TestFailure(
      'detail close timed out: '
      'detail=${find.byType(TournamentDetailPage).evaluate().length}, '
      'marker=${find.byKey(_markerKey).evaluate().length}, '
      'openButton=${find.byKey(_openDetailKey).evaluate().length}',
    );
  }
}

Future<void> _closeDetail(WidgetTester tester) async {
  if (find.byType(TournamentDetailPage).evaluate().isEmpty) return;
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pump();
  await _waitForDetailToClose(tester);
}

TournamentDetailBloc _detailBloc(WidgetTester tester) {
  return tester
      .element(find.byType(TournamentDetailView))
      .read<TournamentDetailBloc>();
}

void main() {
  late _MockLeagueRepository leagueRepository;
  late _MockGroupRepository groupRepository;
  late _MockRemoteConfig remoteConfig;
  late _DetailStreams streams;
  late List<String> toasts;
  late int leagueRepositoryResolutions;
  late int groupRepositoryResolutions;

  setUp(() async {
    await getIt.reset();
    leagueRepository = _MockLeagueRepository();
    groupRepository = _MockGroupRepository();
    remoteConfig = _MockRemoteConfig();
    streams = _DetailStreams();
    toasts = [];
    leagueRepositoryResolutions = 0;
    groupRepositoryResolutions = 0;

    when(() => remoteConfig.adsEnabled).thenReturn(false);
    when(
      () => leagueRepository.listenForLeagueUpdated('L1'),
    ).thenAnswer((_) => streams.league.stream);
    when(
      () => leagueRepository.listenForLeagueStats('L1'),
    ).thenAnswer((_) => streams.stats.stream);
    when(
      () => leagueRepository.listenForMatchesUpdated('L1'),
    ).thenAnswer((_) => streams.matches.stream);
    when(
      () => leagueRepository.getUsersByIds(any()),
    ).thenAnswer((_) async => const {});
    when(() => groupRepository.getGroup(any())).thenAnswer((_) async => null);

    getIt.registerFactory<EsportLeagueRepository>(() {
      leagueRepositoryResolutions++;
      return leagueRepository;
    });
    getIt.registerFactory<EsportGroupRepository>(() {
      groupRepositoryResolutions++;
      return groupRepository;
    });
    getIt.registerSingleton<GNRemoteConfig>(remoteConfig);
    setShowToastImpl(
      (message, {gravity = ToastGravity.BOTTOM}) => toasts.add(message),
    );
  });

  tearDown(() async {
    resetShowToast();
    await streams.close();
    await getIt.reset();
  });

  testWidgets(
    'page resolves both repositories and attaches three streams without reads',
    (tester) async {
      await _openDetail(tester, streams);

      expect(find.byType(TournamentDetailPage), findsOneWidget);
      expect(leagueRepositoryResolutions, 1);
      expect(groupRepositoryResolutions, 1);
      verify(() => leagueRepository.listenForLeagueUpdated('L1')).called(1);
      verify(() => leagueRepository.listenForLeagueStats('L1')).called(1);
      verify(() => leagueRepository.listenForMatchesUpdated('L1')).called(1);
      verifyNever(() => leagueRepository.getLeague(any()));
      verifyNever(() => leagueRepository.getParticipantsAndMatches(any()));
      verifyNever(() => leagueRepository.getLeagueStats(any()));
      verifyNever(() => leagueRepository.getMatches(any()));

      await _closeDetail(tester);
    },
  );

  testWidgets('inactive league snapshot safely returns without a toast', (
    tester,
  ) async {
    await _openDetail(tester, streams);

    streams.league.add(_league(isActive: false));
    await _waitForDetailToClose(tester);

    expect(find.byKey(_markerKey), findsOneWidget);
    expect(find.byType(TournamentDetailPage), findsNothing);
    expect(toasts, isEmpty);
  });

  testWidgets('deleted league snapshot safely returns without a toast', (
    tester,
  ) async {
    await _openDetail(tester, streams);
    final bloc = _detailBloc(tester);

    streams.league.add(_league(isActive: true));
    await _pumpUntil(tester, () => bloc.state.league?.id == 'L1');
    expect(bloc.state.league?.id, 'L1');

    streams.league.add(null);
    await _pumpUntil(tester, () => bloc.state.leagueDeleted);
    expect(bloc.state.leagueDeleted, isTrue);
    await tester.pump();
    await _waitForDetailToClose(tester);

    expect(find.byKey(_markerKey), findsOneWidget);
    expect(find.byType(TournamentDetailPage), findsNothing);
    expect(toasts, isEmpty);
  });

  testWidgets(
    'stats and matches stream errors keep detail open without toast',
    (tester) async {
      await _openDetail(tester, streams);

      streams.stats.addError(StateError('stats unavailable'));
      streams.matches.addError(StateError('matches unavailable'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(TournamentDetailPage), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(toasts, isEmpty);

      await _closeDetail(tester);
    },
  );
}
