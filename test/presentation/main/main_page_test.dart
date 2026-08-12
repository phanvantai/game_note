import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';
import 'package:pes_arena/presentation/main/main_page.dart';
import 'package:pes_arena/presentation/profile/bloc/profile_bloc.dart';

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

void main() {
  setUpAll(() {
    registerFallbackValue(GetEsportGroups());
  });

  setUp(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await getIt.reset();
    final groupBloc = _MockGroupBloc();
    final tournamentBloc = _MockTournamentBloc();
    final profileBloc = _MockProfileBloc();
    final dashboardBloc = _MockDashboardBloc();
    final ongoingBloc = _MockOngoingBloc();
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
    when(() => ongoingBloc.state).thenReturn(const OngoingTournamentsState());
    when(() => remoteConfig.adsEnabled).thenReturn(false);

    getIt.registerFactory<ProfileBloc>(() => profileBloc);
    getIt.registerFactory<GroupBloc>(() => groupBloc);
    getIt.registerFactory<TournamentBloc>(() => tournamentBloc);
    getIt.registerFactory<DashboardBloc>(() => dashboardBloc);
    getIt.registerFactory<OngoingTournamentsBloc>(() => ongoingBloc);
    getIt.registerSingleton<GNRemoteConfig>(remoteConfig);
  });

  tearDown(() => getIt.reset());

  testWidgets(
    'MainPage provides retained blocs and renders four destinations',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MainPage(),
        ),
      );

      expect(find.text('Arena'), findsWidgets);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('Tournaments'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Notifications'), findsNothing);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
    },
  );
}
