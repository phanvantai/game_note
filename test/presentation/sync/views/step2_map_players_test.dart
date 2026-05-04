import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/data/sync/mapping_target.dart';
import 'package:pes_arena/presentation/sync/bloc/sync_bloc.dart';
import 'package:pes_arena/presentation/sync/views/step2_map_players.dart';

import '../../../_helpers/sync_fixtures.dart';

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState> implements SyncBloc {}

Widget _wrap(SyncBloc bloc) => MaterialApp(
      home: Scaffold(
        body: BlocProvider<SyncBloc>.value(
          value: bloc,
          child: const Step2MapPlayers(),
        ),
      ),
    );

void main() {
  setUpAll(() => registerFallbackValue(const SyncRun()));

  testWidgets('shows fallback when no league selected', (tester) async {
    final bloc = _MockSyncBloc();
    when(() => bloc.state).thenReturn(const SyncState());
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('Chưa chọn league'), findsOneWidget);
  });

  testWidgets('renders one row per league player', (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'Anh');
    final p2 = offlinePlayer(2, 'Bình');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague: offlineLeagueFixture(
        players: [p1, p2],
        roundsMatches: const [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('Anh'), findsOneWidget);
    expect(find.text('Bình'), findsOneWidget);
  });

  testWidgets('shows duplicate warning when 2 players map to same uid',
      (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    final p2 = offlinePlayer(2, 'B');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague: offlineLeagueFixture(
        players: [p1, p2],
        roundsMatches: const [],
      ),
      mappings: const {
        1: MapToExisting('same'),
        2: MapToExisting('same'),
      },
    ));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.byKey(const ValueKey('dup-warning')), findsOneWidget);
  });

  testWidgets('Next button disabled until canGoToPreview', (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague: offlineLeagueFixture(
        players: [p1],
        roundsMatches: const [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    final btn = tester.widget<FilledButton>(
      find.byKey(const ValueKey('step2-next')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('tap Next dispatches SyncGoToStep when ready', (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague: offlineLeagueFixture(
        players: [p1],
        roundsMatches: const [],
      ),
      mappings: const {1: MapToExisting('uidA')},
    ));
    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.byKey(const ValueKey('step2-next')));
    verify(() => bloc.add(const SyncGoToStep(SyncStep.preview))).called(1);
  });

  testWidgets('Previous button goes back to step 1', (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague: offlineLeagueFixture(
        players: [p1],
        roundsMatches: const [],
      ),
    ));
    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.byKey(const ValueKey('step2-prev')));
    verify(() => bloc.add(const SyncGoToStep(SyncStep.selectSource))).called(1);
  });

  testWidgets('tap Choose opens picker with members + create option',
      (tester) async {
    final bloc = _MockSyncBloc();
    final p1 = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      selectedLeague: offlineLeagueFixture(
        players: [p1],
        roundsMatches: const [],
      ),
      groupMembers: [onlineUser('U1', displayName: 'Member 1')],
    ));
    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.byKey(const ValueKey('map-btn-1')));
    await tester.pumpAndSettle();
    expect(find.text('Member 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('pick-create-placeholder')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pick-U1')));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const SyncSetMapping(
          playerId: 1,
          target: MapToExisting('U1'),
        ))).called(1);
  });
}
