import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/models/group_overview.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/widgets/group_overview_tab.dart';

class _MockGroupDetailBloc
    extends MockBloc<GroupDetailEvent, GroupDetailState>
    implements GroupDetailBloc {}

class _FakeGroupDetailEvent extends Fake implements GroupDetailEvent {}

GNEsportGroup _group() => GNEsportGroup(
      id: 'G1',
      groupName: 'Test Group',
      ownerId: 'owner1',
      members: const ['owner1'],
      description: '',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: 'active',
    );

GNUser _user(String id, {String? name}) => GNUser(
      id: id,
      displayName: name ?? id,
      phoneNumber: null,
      email: null,
      photoUrl: null,
      role: 'user',
      fcmToken: '',
    );

GNEsportLeague _league(String id, {int year = 2025}) => GNEsportLeague(
      id: id,
      ownerId: 'owner1',
      groupId: 'G1',
      name: 'League $id',
      startDate: DateTime(year, 6, 1),
      isActive: true,
      description: '',
      participants: const [],
    );

GroupDetailState _state({
  ViewStatus overviewStatus = ViewStatus.initial,
  GroupOverview? overview,
  String overviewErrorMessage = '',
  List<GNEsportLeague> leagues = const [],
  int? selectedOverviewYear,
  Map<int, GroupOverview> yearlyOverviews = const {},
  ViewStatus filteredOverviewStatus = ViewStatus.initial,
}) =>
    GroupDetailState(
      group: _group(),
      members: [_user('owner1')],
      currentUserId: 'owner1',
      overviewStatus: overviewStatus,
      overview: overview,
      overviewErrorMessage: overviewErrorMessage,
      leagues: leagues,
      selectedOverviewYear: selectedOverviewYear,
      yearlyOverviews: yearlyOverviews,
      filteredOverviewStatus: filteredOverviewStatus,
    );

Widget _wrap(GroupDetailBloc bloc) {
  return BlocProvider<GroupDetailBloc>.value(
    value: bloc,
    child: const MaterialApp(
      home: Scaffold(body: GroupOverviewTab()),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeGroupDetailEvent());
  });

  testWidgets('hiển thị spinner khi loading lần đầu (overview = null)',
      (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state)
        .thenReturn(_state(overviewStatus: ViewStatus.loading));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('hiển thị empty state khi overview.totalLeagues = 0',
      (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      overviewStatus: ViewStatus.success,
      overview: const GroupOverview.empty(),
    ));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('Group chưa có giải đấu nào'), findsOneWidget);
  });

  testWidgets('hiển thị danh hiệu vô đối với % và display name',
      (tester) async {
    final bloc = _MockGroupDetailBloc();
    final overview = GroupOverview(
      totalLeagues: 6,
      finishedLeagues: 6,
      totalMatchesPlayed: 30,
      totalGoals: 50,
      champion: GroupAward(
        kind: GroupAwardKind.champion,
        player: _user('a', name: 'Alpha'),
        value: 5 / 6,
        sampleSize: 6,
        numerator: 5,
      ),
      runnerUpKing: null,
      drawKing: null,
      ironDefense: null,
      master: null,
      playerStats: const [],
    );
    when(() => bloc.state).thenReturn(_state(
      overviewStatus: ViewStatus.success,
      overview: overview,
    ));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('Vô đối'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.textContaining('83%'), findsOneWidget);
  });

  testWidgets('hiển thị error block khi failure và overview = null',
      (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      overviewStatus: ViewStatus.failure,
      overviewErrorMessage: 'no network',
    ));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.textContaining('Lỗi tải dữ liệu'), findsOneWidget);
  });

  testWidgets(
      'nhấn refresh → confirm → bloc nhận LoadGroupOverview(forceRefresh: true)',
      (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      overviewStatus: ViewStatus.success,
      overview: const GroupOverview.empty(),
    ));
    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(find.text('Cập nhật thống kê?'), findsOneWidget);
    await tester.tap(find.text('Cập nhật'));
    await tester.pumpAndSettle();
    final captured = verify(() => bloc.add(captureAny())).captured;
    expect(captured.any((e) =>
            e is LoadGroupOverview && e.forceRefresh && e.groupId == 'G1'),
        isTrue);
  });

  testWidgets('nhấn refresh → cancel → không emit event', (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      overviewStatus: ViewStatus.success,
      overview: const GroupOverview.empty(),
    ));
    await tester.pumpWidget(_wrap(bloc));
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<LoadGroupOverview>())));
  });

  group('year filter chips', () {
    testWidgets('không hiển thị khi leagues rỗng', (tester) async {
      final bloc = _MockGroupDetailBloc();
      when(() => bloc.state).thenReturn(_state(
        overviewStatus: ViewStatus.success,
        overview: const GroupOverview.empty(),
        leagues: const [],
      ));
      await tester.pumpWidget(_wrap(bloc));
      expect(find.text('Tất cả'), findsNothing);
    });

    testWidgets('hiển thị "Tất cả" + năm khi có leagues', (tester) async {
      final bloc = _MockGroupDetailBloc();
      when(() => bloc.state).thenReturn(_state(
        overviewStatus: ViewStatus.success,
        overview: const GroupOverview.empty(),
        leagues: [_league('L1', year: 2025), _league('L2', year: 2024)],
      ));
      await tester.pumpWidget(_wrap(bloc));
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
    });

    testWidgets('năm trùng nhau chỉ hiện 1 chip', (tester) async {
      final bloc = _MockGroupDetailBloc();
      when(() => bloc.state).thenReturn(_state(
        overviewStatus: ViewStatus.success,
        overview: const GroupOverview.empty(),
        leagues: [
          _league('L1', year: 2025),
          _league('L2', year: 2025),
          _league('L3', year: 2024),
        ],
      ));
      await tester.pumpWidget(_wrap(bloc));
      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2024'), findsOneWidget);
    });

    testWidgets('tap năm → dispatch FilterGroupOverviewByYear(year)',
        (tester) async {
      final bloc = _MockGroupDetailBloc();
      when(() => bloc.state).thenReturn(_state(
        overviewStatus: ViewStatus.success,
        overview: const GroupOverview.empty(),
        leagues: [_league('L1', year: 2025)],
      ));
      await tester.pumpWidget(_wrap(bloc));
      await tester.tap(find.text('2025'));
      verify(() =>
              bloc.add(any(that: isA<FilterGroupOverviewByYear>())))
          .called(1);
    });

    testWidgets('tap "Tất cả" → dispatch FilterGroupOverviewByYear(null)',
        (tester) async {
      final bloc = _MockGroupDetailBloc();
      when(() => bloc.state).thenReturn(_state(
        overviewStatus: ViewStatus.success,
        overview: const GroupOverview.empty(),
        leagues: [_league('L1', year: 2025)],
        selectedOverviewYear: 2025,
      ));
      await tester.pumpWidget(_wrap(bloc));
      await tester.tap(find.text('Tất cả'));
      final captured = verify(() => bloc.add(captureAny())).captured;
      expect(
        captured.any(
            (e) => e is FilterGroupOverviewByYear && e.year == null),
        isTrue,
      );
    });

    testWidgets(
        'filteredOverviewStatus loading + selectedYear != null → hiện spinner',
        (tester) async {
      final bloc = _MockGroupDetailBloc();
      when(() => bloc.state).thenReturn(_state(
        overviewStatus: ViewStatus.success,
        overview: const GroupOverview.empty(),
        leagues: [_league('L1', year: 2025)],
        selectedOverviewYear: 2025,
        filteredOverviewStatus: ViewStatus.loading,
      ));
      await tester.pumpWidget(_wrap(bloc));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('hiển thị yearlyOverview khi selectedYear có data',
        (tester) async {
      final bloc = _MockGroupDetailBloc();
      final filteredOverview = GroupOverview(
        totalLeagues: 2,
        finishedLeagues: 2,
        totalMatchesPlayed: 10,
        totalGoals: 25,
        champion: null,
        runnerUpKing: null,
        drawKing: null,
        ironDefense: null,
        master: null,
        playerStats: [
          GroupPlayerStats(
            player: _user('a', name: 'Alpha'),
            matches: 6,
            wins: 4,
            draws: 1,
            losses: 1,
            goals: 12,
            goalsConceded: 5,
          ),
        ],
      );
      when(() => bloc.state).thenReturn(_state(
        overviewStatus: ViewStatus.success,
        overview: const GroupOverview.empty(),
        leagues: [_league('L1', year: 2025)],
        selectedOverviewYear: 2025,
        yearlyOverviews: {2025: filteredOverview},
        filteredOverviewStatus: ViewStatus.success,
      ));
      await tester.pumpWidget(_wrap(bloc));
      expect(find.text('Alpha'), findsOneWidget);
    });
  });

  testWidgets('refresh button bị disable khi đang loading', (tester) async {
    final bloc = _MockGroupDetailBloc();
    when(() => bloc.state).thenReturn(_state(
      overviewStatus: ViewStatus.loading,
      overview: const GroupOverview.empty(),
    ));
    await tester.pumpWidget(_wrap(bloc));
    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(iconButton.onPressed, isNull);
  });

  testWidgets('hiển thị WDL chip cho mỗi player', (tester) async {
    final bloc = _MockGroupDetailBloc();
    final overview = GroupOverview(
      totalLeagues: 1,
      finishedLeagues: 0,
      totalMatchesPlayed: 5,
      totalGoals: 10,
      champion: null,
      runnerUpKing: null,
      drawKing: null,
      ironDefense: null,
      master: null,
      playerStats: [
        GroupPlayerStats(
          player: _user('a', name: 'Alpha'),
          matches: 10,
          wins: 6,
          draws: 2,
          losses: 2,
          goals: 18,
          goalsConceded: 8,
        ),
      ],
    );
    when(() => bloc.state).thenReturn(_state(
      overviewStatus: ViewStatus.success,
      overview: overview,
    ));
    await tester.pumpWidget(_wrap(bloc));
    expect(find.text('Alpha'), findsOneWidget);
    // 60% T, 20% H, 20% B
    expect(find.text('T 60%'), findsOneWidget);
    expect(find.text('H 20%'), findsOneWidget);
    expect(find.text('B 20%'), findsOneWidget);
  });
}
