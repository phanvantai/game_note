import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/cache/dashboard_cache.dart';
import 'package:pes_arena/core/cache/group_overview_cache.dart';
import 'package:pes_arena/core/cache/h2h_preferences.dart';
import 'package:pes_arena/core/helpers/shared_preferences_helper.dart';
import 'package:pes_arena/core/localization/locale_notifier.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_stats_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/domain/repositories/user_repository.dart';
import 'package:pes_arena/domain/repositories/user_stats_repository.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/api/league_events_hub.dart';
import 'package:pes_arena/data/repositories/api/api_esport_group_repository.dart';
import 'package:pes_arena/data/repositories/api/api_esport_league_repository.dart';
import 'package:pes_arena/data/repositories/api/api_stats_repositories.dart';
import 'package:pes_arena/data/repositories/api/api_user_repository.dart';
import 'package:pes_arena/data/repositories/esport/esport_group_repository_impl.dart';
import 'package:pes_arena/data/repositories/esport/esport_group_stats_repository_impl.dart';
import 'package:pes_arena/data/repositories/esport/esport_league_repository_impl.dart';
import 'package:pes_arena/data/repositories/user_repository_impl.dart';
import 'package:pes_arena/data/repositories/user_stats_repository_impl.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/storage/gn_storage.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:pes_arena/presentation/auth/sign_in/bloc/sign_in_bloc.dart';
import 'package:pes_arena/presentation/auth/third_party/bloc/third_party_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';
import 'package:pes_arena/presentation/profile/bloc/profile_bloc.dart';
import 'package:pes_arena/presentation/profile/change_password/bloc/change_password_bloc.dart';
import 'package:pes_arena/presentation/users/bloc/user_bloc.dart';
import 'package:pes_arena/service/permission_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockGNFirestore extends Mock implements GNFirestore {}

class _MockGNAuth extends Mock implements GNAuth {}

class _MockGNStorage extends Mock implements GNStorage {}

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => getIt.reset());

  test(
    'registers retained online services with injected Firebase seams',
    () async {
      final mockFirestore = _MockGNFirestore();
      final mockAuth = _MockGNAuth();
      final mockStorage = _MockGNStorage();
      when(
        () => mockAuth.authStateChanges(),
      ).thenAnswer((_) => const Stream.empty());

      await init(
        firestore: mockFirestore,
        auth: mockAuth,
        storage: mockStorage,
      );

      expect(getIt<GNFirestore>(), same(mockFirestore));
      expect(getIt<GNAuth>(), same(mockAuth));
      expect(getIt<GNStorage>(), same(mockStorage));
      expect(getIt.isRegistered<SharedPreferencesHelper>(), isTrue);
      expect(getIt.isRegistered<DashboardCache>(), isTrue);
      expect(getIt.isRegistered<GroupOverviewCache>(), isTrue);
      expect(getIt.isRegistered<H2HPreferences>(), isTrue);
      expect(getIt.isRegistered<LocaleNotifier>(), isTrue);
      expect(getIt.isRegistered<PermissionUtil>(), isTrue);
      expect(getIt.isRegistered<AppBloc>(), isTrue);
      expect(getIt.isRegistered<UserRepository>(), isTrue);
      expect(getIt.isRegistered<EsportGroupRepository>(), isTrue);
      expect(getIt.isRegistered<EsportLeagueRepository>(), isTrue);
      expect(getIt.isRegistered<UserStatsRepository>(), isTrue);
      expect(getIt.isRegistered<EsportGroupStatsRepository>(), isTrue);
      expect(getIt.isRegistered<SignInBloc>(), isTrue);
      expect(getIt.isRegistered<ThirdPartyBloc>(), isTrue);
      expect(getIt.isRegistered<ProfileBloc>(), isTrue);
      expect(getIt.isRegistered<ChangePasswordBloc>(), isTrue);
      expect(getIt.isRegistered<GroupBloc>(), isTrue);
      expect(getIt.isRegistered<TournamentBloc>(), isTrue);
      expect(getIt.isRegistered<DashboardBloc>(), isTrue);
      expect(getIt.isRegistered<OngoingTournamentsBloc>(), isTrue);
      expect(getIt.isRegistered<UserBloc>(), isTrue);
    },
  );

  Future<void> initWith({required bool useFirestore}) async {
    final mockAuth = _MockGNAuth();
    when(
      () => mockAuth.authStateChanges(),
    ).thenAnswer((_) => const Stream.empty());
    await init(
      firestore: _MockGNFirestore(),
      auth: mockAuth,
      storage: _MockGNStorage(),
      apiClient: ApiClient(tokenProvider: () async => null),
      useFirestore: useFirestore,
    );
  }

  test('registers the API repositories by default', () async {
    await initWith(useFirestore: false);

    expect(getIt<ApiClient>(), isA<ApiClient>());
    expect(getIt<LeagueEventsHub>(), isA<LeagueEventsHub>());
    expect(getIt<UserRepository>(), isA<ApiUserRepository>());
    expect(getIt<EsportGroupRepository>(), isA<ApiEsportGroupRepository>());
    expect(getIt<EsportLeagueRepository>(), isA<ApiEsportLeagueRepository>());
    expect(getIt<UserStatsRepository>(), isA<ApiUserStatsRepository>());
    expect(
      getIt<EsportGroupStatsRepository>(),
      isA<ApiEsportGroupStatsRepository>(),
    );
  });

  test('keeps the Firestore repositories behind USE_FIRESTORE', () async {
    await initWith(useFirestore: true);

    expect(getIt<UserRepository>(), isA<UserRepositoryImpl>());
    expect(getIt<EsportGroupRepository>(), isA<EsportGroupRepositoryImpl>());
    expect(getIt<EsportLeagueRepository>(), isA<EsportLeagueRepositoryImpl>());
    expect(getIt<UserStatsRepository>(), isA<UserStatsRepositoryImpl>());
    expect(
      getIt<EsportGroupStatsRepository>(),
      isA<EsportGroupStatsRepositoryImpl>(),
    );
  });

  test('does not retain retired registration markers', () {
    final source = File('lib/injection_container.dart').readAsStringSync();

    for (final marker in [
      'GNFirebaseMessaging',
      'GNRemoteConfig',
      'DatabaseManager',
      'NotificationBloc',
      'SyncBloc',
      'OfflineToOnlineMigrator',
      'MobileAds',
      'kIsWeb',
    ]) {
      expect(source, isNot(contains(marker)), reason: marker);
    }
  });
}
