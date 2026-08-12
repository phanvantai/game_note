import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/helpers/shared_preferences_helper.dart';
import 'package:pes_arena/core/localization/locale_notifier.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';
import 'package:pes_arena/presentation/profile/bloc/profile_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:pes_arena/routing.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

class _MockTournamentBloc extends MockBloc<TournamentEvent, TournamentState>
    implements TournamentBloc {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class _MockOngoingTournamentsBloc
    extends MockBloc<OngoingTournamentsEvent, OngoingTournamentsState>
    implements OngoingTournamentsBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(GetEsportGroups());
    registerFallbackValue(LoadProfileEvent());
  });

  setUp(() async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await getIt.reset();
  });

  tearDown(() => getIt.reset());

  Future<GoRouter> pumpRouter(
    WidgetTester tester,
    String initialLocation,
  ) async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesHelper.currentLocale: 'en',
    });
    final sharedPreferences = await SharedPreferences.getInstance();
    final localeNotifier = LocaleNotifier(
      SharedPreferencesHelper(sharedPreferences),
      deviceLocales: const [Locale('en')],
    );
    getIt.registerSingleton<LocaleNotifier>(localeNotifier);
    final appBloc = _MockAppBloc();
    const authenticatedState = AppState(status: AppStatus.authenticated);
    when(() => appBloc.state).thenReturn(authenticatedState);
    whenListen(
      appBloc,
      const Stream<AppState>.empty(),
      initialState: authenticatedState,
    );
    getIt.registerSingleton<AppBloc>(appBloc);

    final groupBloc = _MockGroupBloc();
    when(() => groupBloc.state).thenReturn(const GroupState());
    getIt.registerFactory<GroupBloc>(() => groupBloc);

    final tournamentBloc = _MockTournamentBloc();
    when(() => tournamentBloc.state).thenReturn(const TournamentState());
    getIt.registerFactory<TournamentBloc>(() => tournamentBloc);

    final profileBloc = _MockProfileBloc();
    when(() => profileBloc.state).thenReturn(const ProfileState());
    getIt.registerFactory<ProfileBloc>(() => profileBloc);

    final dashboardBloc = _MockDashboardBloc();
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
    getIt.registerFactory<DashboardBloc>(() => dashboardBloc);

    final ongoingTournamentsBloc = _MockOngoingTournamentsBloc();
    when(
      () => ongoingTournamentsBloc.state,
    ).thenReturn(const OngoingTournamentsState());
    getIt.registerFactory<OngoingTournamentsBloc>(() => ongoingTournamentsBloc);

    final router = createAppRouter(initialLocation: initialLocation);
    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleNotifier>.value(
        value: localeNotifier,
        child: BlocProvider<AppBloc>.value(
          value: appBloc,
          child: MaterialApp.router(
            locale: localeNotifier.currentLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
    return router;
  }

  group('Routing constants', () {
    test('exposes stable route constants', () {
      expect(Routing.app, '/');
      expect(Routing.splash, '/splash');
      expect(Routing.language, '/language');
      expect(Routing.login, '/login');
      expect(Routing.completeProfile, '/complete-profile');
      expect(Routing.groups, '/groups');
      expect(Routing.league, '/league');
      expect(Routing.createTeam, '/create-team');
      expect(Routing.groupDetail, '/group');
      expect(Routing.tournamentDetail, '/tournament');
      expect(Routing.updateProfile, '/update-profile');
      expect(Routing.setting, '/setting');
      expect(Routing.changePassword, '/change-password');
      expect(Routing.dashboardDetail, '/dashboard');
      expect(Routing.feedback, '/feedback');
    });
  });

  group('Routing detail path helpers', () {
    test('builds group and tournament routes from IDs', () {
      expect(Routing.groupDetailPath('group-1'), '/group/group-1');
      expect(Routing.groupDetailPath(''), '/group/');
      expect(
        Routing.tournamentDetailPath('tournament-1'),
        '/tournament/tournament-1',
      );
      expect(Routing.tournamentDetailPath(''), '/tournament/');
    });
  });

  group('Routing.safeNextLocation', () {
    test('handles empty, null, and malformed input', () {
      expect(Routing.safeNextLocation(null), '/');
      expect(Routing.safeNextLocation(''), '/');
      expect(Routing.safeNextLocation('not-a-url%'), '/');
      expect(Routing.safeNextLocation('https://example.com/group/abc'), '/');
      expect(Routing.safeNextLocation('mailto:user@example.com'), '/');
      expect(Routing.safeNextLocation('myapp://foo/bar'), '/');
    });

    test('allows public and fixed protected paths', () {
      for (final path in <String>[
        Routing.language,
        Routing.login,
        Routing.splash,
        Routing.completeProfile,
        Routing.app,
        Routing.groups,
        Routing.updateProfile,
        Routing.setting,
        Routing.changePassword,
        Routing.dashboardDetail,
        Routing.feedback,
      ]) {
        expect(Routing.safeNextLocation(path), path);
      }
    });

    test('preserves query and fragment on valid dynamic routes', () {
      expect(
        Routing.safeNextLocation('/group/group-1?foo=bar&deep=1'),
        '/group/group-1?foo=bar&deep=1',
      );
      expect(
        Routing.safeNextLocation('/tournament/tournament-1?round=final'),
        '/tournament/tournament-1?round=final',
      );
      expect(
        Routing.safeNextLocation('/group/group-1#section'),
        '/group/group-1#section',
      );
    });

    test('rejects unknown or malformed routes', () {
      expect(Routing.safeNextLocation('/group'), '/');
      expect(Routing.safeNextLocation('/tournament'), '/');
      expect(Routing.safeNextLocation('/group/'), '/');
      expect(Routing.safeNextLocation('/tournament/'), '/');
      expect(Routing.safeNextLocation('/group/abc/extra'), '/');
      expect(Routing.safeNextLocation('/legacy-route'), '/');
      expect(Routing.safeNextLocation('/create-team'), '/');
      expect(Routing.safeNextLocation('/legacy-route#unknown'), '/');
      expect(Routing.safeNextLocation('/offline'), Routing.app);
      expect(Routing.safeNextLocation('/offline/league'), Routing.app);
      expect(Routing.safeNextLocation('/sync-offline-data'), Routing.app);
      expect(Routing.safeNextLocation('/notification'), Routing.app);
    });
  });

  testWidgets('direct retired routes resolve home instead of not found', (
    tester,
  ) async {
    for (final path in <String>[
      '/offline',
      '/offline/league',
      '/sync-offline-data',
    ]) {
      final router = await pumpRouter(tester, path);

      expect(router.routeInformationProvider.value.uri.path, Routing.app);
      expect(find.text('Page not found'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await getIt.reset();
    }
  });
}
