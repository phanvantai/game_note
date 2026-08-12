import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';
import 'package:pes_arena/presentation/main/main_view.dart';
import 'package:pes_arena/presentation/profile/bloc/profile_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';

class _MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

class _MockTournamentBloc extends MockBloc<TournamentEvent, TournamentState>
    implements TournamentBloc {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class _MockOngoingBloc
    extends MockBloc<OngoingTournamentsEvent, OngoingTournamentsState>
    implements OngoingTournamentsBloc {}

class _MockRemoteConfig extends Mock implements GNRemoteConfig {}

Widget _wrap({
  required GroupBloc groupBloc,
  required TournamentBloc tournamentBloc,
  required ProfileBloc profileBloc,
  required DashboardBloc dashboardBloc,
  required OngoingTournamentsBloc ongoingBloc,
  Locale locale = const Locale('vi'),
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AppBloc>(create: (_) => AppBloc()),
      BlocProvider<GroupBloc>.value(value: groupBloc),
      BlocProvider<TournamentBloc>.value(value: tournamentBloc),
      BlocProvider<ProfileBloc>.value(value: profileBloc),
      BlocProvider<DashboardBloc>.value(value: dashboardBloc),
      BlocProvider<OngoingTournamentsBloc>.value(value: ongoingBloc),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const MainView(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(GetEsportGroups());
    registerFallbackValue(LoadProfileEvent());
  });

  setUp(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await getIt.reset();
    final remoteConfig = _MockRemoteConfig();
    when(() => remoteConfig.adsEnabled).thenReturn(false);
    getIt.registerSingleton<GNRemoteConfig>(remoteConfig);
  });

  tearDown(() => getIt.reset());

  testWidgets('MainView renders four destinations and switches tabs', (
    tester,
  ) async {
    final groupBloc = _MockGroupBloc();
    final tournamentBloc = _MockTournamentBloc();
    final profileBloc = _MockProfileBloc();
    final dashboardBloc = _MockDashboardBloc();
    final ongoingBloc = _MockOngoingBloc();
    when(() => groupBloc.state).thenReturn(const GroupState());
    when(() => ongoingBloc.state).thenReturn(const OngoingTournamentsState());
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
    await tester.pumpWidget(
      _wrap(
        groupBloc: groupBloc,
        tournamentBloc: tournamentBloc,
        profileBloc: profileBloc,
        dashboardBloc: dashboardBloc,
        ongoingBloc: ongoingBloc,
      ),
    );

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Thông báo'), findsNothing);
    verify(() => groupBloc.add(any(that: isA<GetEsportGroups>()))).called(1);

    await tester.tap(find.text('Giải đấu'));
    await tester.pumpAndSettle();

    expect(find.text('Tham gia'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.group_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Nhóm của tôi'), findsOneWidget);

    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    verify(() => profileBloc.add(any(that: isA<LoadProfileEvent>()))).called(1);
  });

  testWidgets('MainView bottom labels use English locale', (tester) async {
    final groupBloc = _MockGroupBloc();
    final tournamentBloc = _MockTournamentBloc();
    final profileBloc = _MockProfileBloc();
    final dashboardBloc = _MockDashboardBloc();
    final ongoingBloc = _MockOngoingBloc();
    when(() => groupBloc.state).thenReturn(const GroupState());
    when(() => ongoingBloc.state).thenReturn(const OngoingTournamentsState());
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
    await tester.pumpWidget(
      _wrap(
        groupBloc: groupBloc,
        tournamentBloc: tournamentBloc,
        profileBloc: profileBloc,
        dashboardBloc: dashboardBloc,
        ongoingBloc: ongoingBloc,
        locale: const Locale('en'),
      ),
    );

    expect(find.text('Arena'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Tournaments'), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Nhóm'), findsNothing);
    expect(find.text('Giải đấu'), findsNothing);
  });
}
