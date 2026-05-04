import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/firestore/notification/gn_notification.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/home_page.dart';
import 'package:pes_arena/presentation/notification/bloc/notification_bloc.dart';

class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class _MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

class _MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

GNNotification _notification({required bool isRead}) => GNNotification(
  id: 'n1',
  userId: 'u1',
  title: 'Title',
  message: 'Message',
  type: GNNotificationType.unknown.value,
  timestamp: DateTime(2026, 1, 1),
  isRead: isRead,
);

Widget _wrap({
  required DashboardBloc dashboardBloc,
  required NotificationBloc notificationBloc,
  required GroupBloc groupBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<DashboardBloc>.value(value: dashboardBloc),
      BlocProvider<NotificationBloc>.value(value: notificationBloc),
      BlocProvider<GroupBloc>.value(value: groupBloc),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/notification',
            builder: (context, state) => const Text('notification page'),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(LoadDashboard());
  });

  testWidgets('render tab home và notification badge/tap', (tester) async {
    final dashboardBloc = _MockDashboardBloc();
    final notificationBloc = _MockNotificationBloc();
    final groupBloc = _MockGroupBloc();
    when(() => dashboardBloc.state).thenReturn(
      const DashboardState(
        viewStatus: ViewStatus.success,
        stats: DashboardStats(
          tournamentsJoined: 0,
          finishedTournaments: 0,
          championCount: 0,
          runnerUpCount: 0,
          lastChampionAt: null,
          recentMatches: [],
        ),
      ),
    );
    when(() => notificationBloc.state).thenReturn(
      NotificationState(notifications: [_notification(isRead: false)]),
    );
    when(() => groupBloc.state).thenReturn(const GroupState());

    await tester.pumpWidget(
      _wrap(
        dashboardBloc: dashboardBloc,
        notificationBloc: notificationBloc,
        groupBloc: groupBloc,
      ),
    );

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Bảng điều khiển'), findsOneWidget);
    expect(find.text('Nhóm'), findsOneWidget);
    expect(find.byType(Container), findsWidgets);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('notification page'), findsOneWidget);
  });

  testWidgets('switch sang tab Nhóm render GroupsView embedded', (
    tester,
  ) async {
    final dashboardBloc = _MockDashboardBloc();
    final notificationBloc = _MockNotificationBloc();
    final groupBloc = _MockGroupBloc();
    when(() => dashboardBloc.state).thenReturn(
      const DashboardState(
        viewStatus: ViewStatus.success,
        stats: DashboardStats(
          tournamentsJoined: 0,
          finishedTournaments: 0,
          championCount: 0,
          runnerUpCount: 0,
          lastChampionAt: null,
          recentMatches: [],
        ),
      ),
    );
    when(() => notificationBloc.state).thenReturn(const NotificationState());
    when(() => groupBloc.state).thenReturn(const GroupState());

    await tester.pumpWidget(
      _wrap(
        dashboardBloc: dashboardBloc,
        notificationBloc: notificationBloc,
        groupBloc: groupBloc,
      ),
    );

    await tester.tap(find.text('Nhóm'));
    await tester.pumpAndSettle();

    expect(find.text('Nhóm của tôi'), findsOneWidget);
    expect(find.text('Nhóm khác'), findsOneWidget);
    expect(find.text('Tạo nhóm'), findsOneWidget);
  });
}
