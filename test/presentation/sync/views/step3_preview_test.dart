import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/data/sync/mapping_target.dart';
import 'package:pes_arena/data/sync/migration_plan.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/presentation/sync/bloc/sync_bloc.dart';
import 'package:pes_arena/presentation/sync/views/step3_preview.dart';

import '../../../_helpers/sync_fixtures.dart';

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState> implements SyncBloc {}

Widget _wrap(SyncBloc bloc) => MaterialApp(
      home: Scaffold(
        body: BlocProvider<SyncBloc>.value(
          value: bloc,
          child: const Step3Preview(),
        ),
      ),
    );

PlannedStatDoc _stat(
  String uid, {
  int wins = 0,
  int draws = 0,
  int losses = 0,
  int gf = 0,
  int ga = 0,
}) =>
    PlannedStatDoc(
      id: 'stat-$uid',
      userId: uid,
      matchesPlayed: wins + draws + losses,
      goals: gf,
      goalsConceded: ga,
      wins: wins,
      draws: draws,
      losses: losses,
    );

GNEsportMatch _match(
  String home,
  String away,
  int hs,
  int as_, {
  String? id,
}) =>
    GNEsportMatch(
      id: id ?? 'm-$home-$away',
      homeTeamId: home,
      awayTeamId: away,
      homeScore: hs,
      awayScore: as_,
      date: DateTime(2024, 1, 1),
      isFinished: true,
      leagueId: 'L1',
    );

void main() {
  setUpAll(() => registerFallbackValue(const SyncRun()));

  testWidgets('shows fallback when missing data', (tester) async {
    final bloc = _MockSyncBloc();
    when(() => bloc.state).thenReturn(const SyncState());
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
  });

  testWidgets('shows both Offline and Online tabs', (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague:
          offlineLeagueFixture(players: [p1], roundsMatches: const []),
      selectedGroup: onlineGroup('G'),
      groupMembers: [onlineUser('uA')],
      mappings: const {1: MapToExisting('uA')},
      plan: const MigrationPlan(
        placeholderUsers: [],
        groupId: 'G',
        uidsToAddToGroup: ['uA'],
        leagueId: 'L1',
        leagueData: {},
        participantUids: ['uA'],
        statDocs: [],
        matches: [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.byKey(const ValueKey('tab-offline')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab-online')), findsOneWidget);
  });

  testWidgets('Offline tab shows offline standings + matches',
      (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'Anh');
    final p2 = offlinePlayer(2, 'Bình');
    final league = offlineLeagueFixture(
      players: [p1, p2],
      roundsMatches: [
        [
          offlineMatch(
            matchId: 10,
            roundId: 1,
            home: p1,
            away: p2,
            homeScore: 3,
            awayScore: 1,
          ),
        ],
      ],
    );
    // Player stats with pre-computed wins/draws/losses (offline DB shape).
    final hydratedLeague = league.copyWith(
      players: [
        league.players[0].copyWith(totalPlayed: 1, wins: 1),
        league.players[1].copyWith(totalPlayed: 1, losses: 1),
      ],
    );
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague: hydratedLeague,
      selectedGroup: onlineGroup('G'),
      groupMembers: const [],
      mappings: const {
        1: MapToExisting('uA'),
        2: MapToExisting('uB'),
      },
      plan: const MigrationPlan(
        placeholderUsers: [],
        groupId: 'G',
        uidsToAddToGroup: ['uA', 'uB'],
        leagueId: 'L1',
        leagueData: {},
        participantUids: ['uA', 'uB'],
        statDocs: [],
        matches: [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    // Offline tab shown by default (first tab).
    expect(find.text('Anh'), findsWidgets);
    expect(find.text('Bình'), findsWidgets);
    expect(find.text('3  -  1'), findsOneWidget);
  });

  testWidgets('Online tab shows resolved names from group members',
      (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague:
          offlineLeagueFixture(players: [p1], roundsMatches: const []),
      selectedGroup: onlineGroup('G'),
      groupMembers: [onlineUser('uA', displayName: 'Alice Online')],
      mappings: const {1: MapToExisting('uA')},
      plan: MigrationPlan(
        placeholderUsers: const [],
        groupId: 'G',
        uidsToAddToGroup: const ['uA'],
        leagueId: 'L1',
        leagueData: const {},
        participantUids: const ['uA'],
        statDocs: [_stat('uA')],
        matches: const [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    // Switch to Online tab.
    await tester.tap(find.byKey(const ValueKey('tab-online')));
    await tester.pumpAndSettle();
    expect(find.text('Alice Online'), findsOneWidget);
  });

  testWidgets('Online tab renders standings sorted by pts → GD → GF → name',
      (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague:
          offlineLeagueFixture(players: [p1], roundsMatches: const []),
      selectedGroup: onlineGroup('G'),
      groupMembers: [
        onlineUser('uA', displayName: 'Alice'),
        onlineUser('uB', displayName: 'Bob'),
        onlineUser('uC', displayName: 'Carol'),
      ],
      mappings: const {1: MapToExisting('uA')},
      plan: MigrationPlan(
        placeholderUsers: const [],
        groupId: 'G',
        uidsToAddToGroup: const ['uA', 'uB', 'uC'],
        leagueId: 'L1',
        leagueData: const {},
        participantUids: const ['uA', 'uB', 'uC'],
        statDocs: [
          // Alice: 1W (3pts) GD+1
          _stat('uA', wins: 1, gf: 2, ga: 1),
          // Bob: 1W 1D (4pts) GD+2 → top
          _stat('uB', wins: 1, draws: 1, gf: 3, ga: 1),
          // Carol: 0pts
          _stat('uC', losses: 2, gf: 0, ga: 4),
        ],
        matches: const [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    // Switch to Online tab.
    await tester.tap(find.byKey(const ValueKey('tab-online')));
    await tester.pumpAndSettle();

    // Online standings table is the second DataTable in tree (after offline
    // tab, which renders 0 players → empty table). Use last() to grab online.
    final table =
        tester.widgetList<DataTable>(find.byType(DataTable)).last;
    expect(table.rows.map((r) => r.key).toList(), [
      const ValueKey('standings-uB'), // Bob top (4pts)
      const ValueKey('standings-uA'), // Alice (3pts)
      const ValueKey('standings-uC'), // Carol (0pts)
    ]);
  });

  testWidgets('Online tab renders matches with resolved names + scores',
      (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague:
          offlineLeagueFixture(players: [p1], roundsMatches: const []),
      selectedGroup: onlineGroup('G'),
      groupMembers: [
        onlineUser('uA', displayName: 'Alice'),
        onlineUser('uB', displayName: 'Bob'),
      ],
      mappings: const {1: MapToExisting('uA')},
      plan: MigrationPlan(
        placeholderUsers: const [],
        groupId: 'G',
        uidsToAddToGroup: const ['uA', 'uB'],
        leagueId: 'L1',
        leagueData: const {},
        participantUids: const ['uA', 'uB'],
        statDocs: [_stat('uA'), _stat('uB')],
        matches: [_match('uA', 'uB', 3, 1)],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.byKey(const ValueKey('tab-online')));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Bob'), findsWidgets);
    expect(find.text('3  -  1'), findsOneWidget);
  });

  testWidgets('Online tab shows placeholders with (mới) suffix',
      (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague:
          offlineLeagueFixture(players: [p1], roundsMatches: const []),
      selectedGroup: onlineGroup('G'),
      groupMembers: const [],
      mappings: const {1: CreatePlaceholder('Newbie')},
      plan: const MigrationPlan(
        placeholderUsers: [
          PlannedPlaceholder(id: 'placeholder_X', displayName: 'Newbie'),
        ],
        groupId: 'G',
        uidsToAddToGroup: ['placeholder_X'],
        leagueId: 'L1',
        leagueData: {},
        participantUids: ['placeholder_X'],
        statDocs: [
          PlannedStatDoc(
            id: 's1',
            userId: 'placeholder_X',
            matchesPlayed: 0,
            goals: 0,
            goalsConceded: 0,
            wins: 0,
            draws: 0,
            losses: 0,
          ),
        ],
        matches: [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.byKey(const ValueKey('tab-online')));
    await tester.pumpAndSettle();
    expect(find.text('Newbie (mới)'), findsWidgets);
    // Placeholder footer section in Online tab.
    expect(
        find.byKey(const ValueKey('placeholder-placeholder_X')), findsOneWidget);
  });

  testWidgets('shows empty state when no matches', (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague:
          offlineLeagueFixture(players: [p1], roundsMatches: const []),
      selectedGroup: onlineGroup('G'),
      groupMembers: [onlineUser('uA')],
      plan: const MigrationPlan(
        placeholderUsers: [],
        groupId: 'G',
        uidsToAddToGroup: ['uA'],
        leagueId: 'L1',
        leagueData: {},
        participantUids: ['uA'],
        statDocs: [],
        matches: [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    // Both tabs show "Không có trận nào đã đấu" empty state.
    expect(find.text('Không có trận nào đã đấu'), findsWidgets);
  });

  testWidgets('Confirm button dispatches SyncRun', (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague:
          offlineLeagueFixture(players: [p1], roundsMatches: const []),
      selectedGroup: onlineGroup('G'),
      mappings: const {1: MapToExisting('U1')},
      plan: const MigrationPlan(
        placeholderUsers: [],
        groupId: 'G',
        uidsToAddToGroup: ['U1'],
        leagueId: 'L1',
        leagueData: {},
        participantUids: ['U1'],
        statDocs: [],
        matches: [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.byKey(const ValueKey('confirm-sync')));
    verify(() => bloc.add(const SyncRun())).called(1);
  });

  testWidgets('Previous button goes back to step 2', (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague:
          offlineLeagueFixture(players: [p1], roundsMatches: const []),
      selectedGroup: onlineGroup('G'),
      mappings: const {1: MapToExisting('U1')},
      plan: const MigrationPlan(
        placeholderUsers: [],
        groupId: 'G',
        uidsToAddToGroup: ['U1'],
        leagueId: 'L1',
        leagueData: {},
        participantUids: ['U1'],
        statDocs: [],
        matches: [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.byKey(const ValueKey('step3-prev')));
    verify(() => bloc.add(const SyncGoToStep(SyncStep.mapPlayers))).called(1);
  });

  testWidgets('shows ops count', (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague:
          offlineLeagueFixture(players: [p1], roundsMatches: const []),
      selectedGroup: onlineGroup('G'),
      mappings: const {1: MapToExisting('U1')},
      plan: const MigrationPlan(
        placeholderUsers: [],
        groupId: 'G',
        uidsToAddToGroup: ['U1'],
        leagueId: 'L1',
        leagueData: {},
        participantUids: ['U1'],
        statDocs: [],
        matches: [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.byKey(const ValueKey('ops-count')), findsOneWidget);
  });
}
