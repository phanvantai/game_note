import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/messaging/gn_firebase_messaging.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/main/main_page.dart';
import 'package:pes_arena/presentation/notification/bloc/notification_bloc.dart';
import 'package:pes_arena/presentation/profile/bloc/profile_bloc.dart';

class _MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

class _MockTournamentBloc extends MockBloc<TournamentEvent, TournamentState>
    implements TournamentBloc {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class _MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

class _MockMessaging extends Mock implements GNFirebaseMessaging {}

class _MockRemoteConfig extends Mock implements GNRemoteConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(GetEsportGroups());
    registerFallbackValue(NotificationEventFetch());
  });

  setUp(() async {
    await getIt.reset();
    final groupBloc = _MockGroupBloc();
    final tournamentBloc = _MockTournamentBloc();
    final profileBloc = _MockProfileBloc();
    final dashboardBloc = _MockDashboardBloc();
    final notificationBloc = _MockNotificationBloc();
    final messaging = _MockMessaging();
    final remoteConfig = _MockRemoteConfig();

    when(() => groupBloc.state).thenReturn(const GroupState());
    when(() => tournamentBloc.state).thenReturn(const TournamentState());
    when(() => profileBloc.state).thenReturn(const ProfileState());
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
    when(() => messaging.initialize()).thenAnswer((_) async {});
    when(() => remoteConfig.adsEnabled).thenReturn(false);

    getIt.registerFactory<ProfileBloc>(() => profileBloc);
    getIt.registerFactory<GroupBloc>(() => groupBloc);
    getIt.registerFactory<TournamentBloc>(() => tournamentBloc);
    getIt.registerFactory<DashboardBloc>(() => dashboardBloc);
    getIt.registerSingleton<NotificationBloc>(notificationBloc);
    getIt.registerSingleton<GNFirebaseMessaging>(messaging);
    getIt.registerSingleton<GNRemoteConfig>(remoteConfig);
  });

  tearDown(() => getIt.reset());

  testWidgets('MainPage provide các bloc và render MainView', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainPage()));

    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.text('Giải đấu'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);
    final notificationBloc = getIt<NotificationBloc>();
    verify(
      () => notificationBloc.add(any(that: isA<NotificationEventFetch>())),
    ).called(1);
  });
}
