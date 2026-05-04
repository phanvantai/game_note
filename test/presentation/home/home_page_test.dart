import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/home_page.dart';
import 'package:pes_arena/presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';

class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class _MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

class _MockOngoingBloc
    extends MockBloc<OngoingTournamentsEvent, OngoingTournamentsState>
    implements OngoingTournamentsBloc {}

class _FakeGroupState extends Mock implements GroupState {}

GroupState _groupStateWith(List<GNEsportGroup> userGroups) {
  final state = _FakeGroupState();
  when(() => state.userGroups).thenReturn(userGroups);
  when(() => state.otherGroups).thenReturn(const []);
  when(() => state.viewStatus).thenReturn(ViewStatus.success);
  return state;
}

GNEsportGroup _group(String id) => GNEsportGroup(
  id: id,
  groupName: 'g$id',
  ownerId: 'u1',
  members: const ['u1'],
  description: '',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  status: 'active',
);

GNEsportLeague _league({
  required String id,
  required String name,
  required DateTime start,
  DateTime? end,
}) => GNEsportLeague(
  id: id,
  ownerId: 'u1',
  groupId: 'g1',
  name: name,
  startDate: start,
  endDate: end,
  isActive: true,
  description: '',
  participants: const [],
  rankPayoutEnabled: false,
  rankPayouts: const [],
  defaultMatchCost: 0,
);

DashboardState _emptyDashboard() => const DashboardState(
  viewStatus: ViewStatus.success,
  stats: DashboardStats(
    tournamentsJoined: 0,
    finishedTournaments: 0,
    championCount: 0,
    runnerUpCount: 0,
    lastChampionAt: null,
    recentMatches: [],
  ),
);

Widget _wrap({
  required DashboardBloc dashboardBloc,
  required GroupBloc groupBloc,
  required OngoingTournamentsBloc ongoingBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<DashboardBloc>.value(value: dashboardBloc),
      BlocProvider<GroupBloc>.value(value: groupBloc),
      BlocProvider<OngoingTournamentsBloc>.value(value: ongoingBloc),
    ],
    child: const MaterialApp(home: HomePage()),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(LoadDashboard());
    registerFallbackValue(const LoadOngoingTournaments([]));
  });

  testWidgets('initState dispatch LoadOngoingTournaments với group ids', (
    tester,
  ) async {
    final dashboardBloc = _MockDashboardBloc();
    final groupBloc = _MockGroupBloc();
    final ongoingBloc = _MockOngoingBloc();
    when(() => dashboardBloc.state).thenReturn(_emptyDashboard());
    final groupState = _groupStateWith([_group('g1'), _group('g2')]);
    when(() => groupBloc.state).thenReturn(groupState);
    when(() => ongoingBloc.state).thenReturn(const OngoingTournamentsState());

    await tester.pumpWidget(
      _wrap(
        dashboardBloc: dashboardBloc,
        groupBloc: groupBloc,
        ongoingBloc: ongoingBloc,
      ),
    );

    final captured = verify(
      () => ongoingBloc.add(captureAny(that: isA<LoadOngoingTournaments>())),
    ).captured;
    expect(captured, hasLength(1));
    final event = captured.first as LoadOngoingTournaments;
    expect(event.groupIds, ['g1', 'g2']);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('không dispatch lại nếu loadedGroupIds khớp với userGroups', (
    tester,
  ) async {
    final dashboardBloc = _MockDashboardBloc();
    final groupBloc = _MockGroupBloc();
    final ongoingBloc = _MockOngoingBloc();
    when(() => dashboardBloc.state).thenReturn(_emptyDashboard());
    final groupState = _groupStateWith([_group('g1'), _group('g2')]);
    when(() => groupBloc.state).thenReturn(groupState);
    when(() => ongoingBloc.state).thenReturn(
      const OngoingTournamentsState(loadedGroupIds: ['g2', 'g1']),
    );

    await tester.pumpWidget(
      _wrap(
        dashboardBloc: dashboardBloc,
        groupBloc: groupBloc,
        ongoingBloc: ongoingBloc,
      ),
    );

    verifyNever(
      () => ongoingBloc.add(any(that: isA<LoadOngoingTournaments>())),
    );
  });

  testWidgets(
    'banner hiện khi có giải đấu ongoing và ẩn giải đã kết thúc',
    (tester) async {
      final now = DateTime.now();
      final dashboardBloc = _MockDashboardBloc();
      final groupBloc = _MockGroupBloc();
      final ongoingBloc = _MockOngoingBloc();
      when(() => dashboardBloc.state).thenReturn(_emptyDashboard());
      when(() => groupBloc.state).thenReturn(const GroupState());
      when(() => ongoingBloc.state).thenReturn(
        OngoingTournamentsState(
          status: ViewStatus.success,
          leagues: [
            _league(
              id: 'l1',
              name: 'Đang chạy',
              start: now.subtract(const Duration(days: 2)),
              end: now.add(const Duration(days: 2)),
            ),
            _league(
              id: 'l2',
              name: 'Đã kết thúc',
              start: now.subtract(const Duration(days: 10)),
              end: now.subtract(const Duration(days: 5)),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _wrap(
          dashboardBloc: dashboardBloc,
          groupBloc: groupBloc,
          ongoingBloc: ongoingBloc,
        ),
      );

      expect(find.text('Giải đấu đang diễn ra'), findsOneWidget);
      expect(find.text('Đang chạy'), findsOneWidget);
      expect(find.text('Đã kết thúc'), findsNothing);
    },
  );
}
