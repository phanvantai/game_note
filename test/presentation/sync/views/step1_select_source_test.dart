import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/presentation/sync/bloc/sync_bloc.dart';
import 'package:pes_arena/presentation/sync/views/step1_select_source.dart';

import '../../../_helpers/sync_fixtures.dart';

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState> implements SyncBloc {}


Widget _wrap(SyncBloc bloc) => MaterialApp(
      home: Scaffold(
        body: BlocProvider<SyncBloc>.value(value: bloc, child: const Step1SelectSource()),
      ),
    );

void main() {
  setUpAll(() => registerFallbackValue(const SyncRun()));

  testWidgets('shows progress when loading + empty', (tester) async {
    final bloc = _MockSyncBloc();
    when(() => bloc.state).thenReturn(
      const SyncState(status: SyncStatus.loading),
    );
    await tester.pumpWidget(_wrap(bloc));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty placeholder when no offline leagues', (tester) async {
    final bloc = _MockSyncBloc();
    when(() => bloc.state).thenReturn(const SyncState(status: SyncStatus.ready));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('Không có league offline nào để đồng bộ'), findsOneWidget);
  });

  testWidgets('renders leagues + groups + tap dispatches events', (tester) async {
    final bloc = _MockSyncBloc();
    final p = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      status: SyncStatus.ready,
      offlineLeagues: [
        offlineLeagueFixture(id: 1, name: 'L1', players: [p], roundsMatches: const []),
      ],
      myGroups: [onlineGroup('G1', groupName: 'Group 1')],
    ));

    await tester.pumpWidget(_wrap(bloc));

    expect(find.text('L1'), findsOneWidget);
    expect(find.text('Group 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('offline-1')));
    verify(() => bloc.add(const SyncSelectOfflineLeague(1))).called(1);

    await tester.tap(find.byKey(const ValueKey('group-G1')));
    verify(() => bloc.add(const SyncSelectGroup('G1'))).called(1);
  });

  testWidgets('disables Next button when nothing selected', (tester) async {
    final bloc = _MockSyncBloc();
    final p = offlinePlayer(1, 'A');
    when(() => bloc.state).thenReturn(SyncState(
      status: SyncStatus.ready,
      offlineLeagues: [
        offlineLeagueFixture(id: 1, name: 'L1', players: [p], roundsMatches: const []),
      ],
      myGroups: [onlineGroup('G1')],
    ));
    await tester.pumpWidget(_wrap(bloc));
    final btn = tester.widget<FilledButton>(find.byKey(const ValueKey('step1-next')));
    expect(btn.onPressed, isNull);
  });

  testWidgets('enables Next + tap dispatches go-to-step event',
      (tester) async {
    final bloc = _MockSyncBloc();
    final p = offlinePlayer(1, 'A');
    final l = offlineLeagueFixture(
      id: 1,
      name: 'L1',
      players: [p],
      roundsMatches: const [],
    );
    when(() => bloc.state).thenReturn(SyncState(
      status: SyncStatus.ready,
      offlineLeagues: [l],
      myGroups: [onlineGroup('G1')],
      selectedLeague: l,
      selectedGroup: onlineGroup('G1'),
    ));
    await tester.pumpWidget(_wrap(bloc));
    final btn = tester.widget<FilledButton>(find.byKey(const ValueKey('step1-next')));
    expect(btn.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('step1-next')));
    verify(() => bloc.add(const SyncGoToStep(SyncStep.mapPlayers))).called(1);
  });

  testWidgets('shows error message in error state', (tester) async {
    final bloc = _MockSyncBloc();
    when(() => bloc.state).thenReturn(const SyncState(
      status: SyncStatus.error,
      errorMessage: 'oops',
    ));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('oops'), findsOneWidget);
  });
}
