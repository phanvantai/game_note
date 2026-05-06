import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/presentation/sync/bloc/sync_bloc.dart';
import 'package:pes_arena/presentation/sync/views/step4_progress.dart';

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState> implements SyncBloc {}

Widget _wrap(SyncBloc bloc) => MaterialApp(
      home: Scaffold(
        body: BlocProvider<SyncBloc>.value(
          value: bloc,
          child: const Step4Progress(),
        ),
      ),
    );

void main() {
  setUpAll(() => registerFallbackValue(const SyncRun()));

  testWidgets('renders indeterminate progress + custom label while running',
      (tester) async {
    final bloc = _MockSyncBloc();
    when(() => bloc.state).thenReturn(const SyncState(
      status: SyncStatus.running,
      progressLabel: 'Đang ghi 5 bản ghi lên server...',
    ));
    await tester.pumpWidget(_wrap(bloc));
    final indicator =
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    // null = indeterminate (atomic batch can't report mid-progress).
    expect(indicator.value, isNull);
    expect(find.text('Đang ghi 5 bản ghi lên server...'), findsOneWidget);
    expect(find.textContaining('không đóng app'), findsOneWidget);
  });

  testWidgets('PopScope blocks back when running', (tester) async {
    final bloc = _MockSyncBloc();
    when(() => bloc.state).thenReturn(const SyncState(
      status: SyncStatus.running,
    ));
    await tester.pumpWidget(_wrap(bloc));
    final pop = tester.widget<PopScope>(find.byType(PopScope));
    expect(pop.canPop, isFalse);
  });

  testWidgets('PopScope allows pop in non-running states', (tester) async {
    final bloc = _MockSyncBloc();
    when(() => bloc.state).thenReturn(const SyncState(
      status: SyncStatus.success,
    ));
    await tester.pumpWidget(_wrap(bloc));
    final pop = tester.widget<PopScope>(find.byType(PopScope));
    expect(pop.canPop, isTrue);
  });

  testWidgets('renders error state with retry + back buttons',
      (tester) async {
    final bloc = _MockSyncBloc();
    when(() => bloc.state).thenReturn(const SyncState(
      status: SyncStatus.error,
      errorMessage: 'oops',
    ));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('oops'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('retry')));
    verify(() => bloc.add(const SyncRun())).called(1);

    await tester.tap(find.text('Quay lại'));
    verify(() => bloc.add(const SyncGoToStep(SyncStep.preview))).called(1);
  });
}
