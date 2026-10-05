// coverage:ignore-file

import 'package:pes_arena/presentation/profile/change_password/bloc/change_password_bloc.dart';
import 'package:pes_arena/service/permission_util.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/league_events_hub.dart';
import 'core/cache/dashboard_cache.dart';
import 'core/cache/group_overview_cache.dart';
import 'core/cache/h2h_preferences.dart';
import 'core/helpers/shared_preferences_helper.dart';
import 'core/localization/locale_notifier.dart';
import 'data/repositories/api/api_esport_group_repository.dart';
import 'data/repositories/api/api_esport_league_repository.dart';
import 'data/repositories/api/api_stats_repositories.dart';
import 'data/repositories/api/api_user_repository.dart';
import 'data/repositories/esport/esport_group_stats_repository_impl.dart';
import 'data/repositories/user_stats_repository_impl.dart';
import 'domain/repositories/esport/esport_group_stats_repository.dart';
import 'domain/repositories/user_stats_repository.dart';
import 'data/repositories/esport/esport_group_repository_impl.dart';
import 'data/repositories/esport/esport_league_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'domain/repositories/esport/esport_group_repository.dart';
import 'domain/repositories/esport/esport_league_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'firebase/firestore/gn_firestore.dart';
import 'firebase/storage/gn_storage.dart';
import 'presentation/app/bloc/app_bloc.dart';
import 'presentation/auth/sign_in/bloc/sign_in_bloc.dart';
import 'presentation/auth/third_party/bloc/third_party_bloc.dart';
import 'firebase/auth/gn_auth.dart';
import 'presentation/esport/groups/bloc/group_bloc.dart';
import 'presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';
import 'presentation/profile/bloc/profile_bloc.dart';
import 'presentation/users/bloc/user_bloc.dart';

final getIt = GetIt.instance;

Future<void> init({
  GNFirestore? firestore,
  GNAuth? auth,
  GNStorage? storage,
  ApiClient? apiClient,
  bool useFirestore = ApiConfig.useFirestore,
}) async {
  getIt.registerSingletonAsync<SharedPreferences>(
    () => SharedPreferences.getInstance(),
  );
  getIt.registerSingleton(
    SharedPreferencesHelper(await getIt.getAsync<SharedPreferences>()),
  );

  getIt.registerSingleton(
    DashboardCache(await getIt.getAsync<SharedPreferences>()),
  );

  getIt.registerSingleton(
    GroupOverviewCache(await getIt.getAsync<SharedPreferences>()),
  );

  getIt.registerSingleton(
    H2HPreferences(await getIt.getAsync<SharedPreferences>()),
  );

  getIt.registerSingleton(LocaleNotifier(getIt()));

  getIt.registerSingleton(PermissionUtil());

  // firebase service
  getIt.registerSingleton(firestore ?? GNFirestore());
  getIt.registerSingleton(auth ?? GNAuth());
  getIt.registerSingleton(storage ?? GNStorage());

  // backend
  getIt.registerSingleton(apiClient ?? ApiClient());
  getIt.registerSingleton(LeagueEventsHub(getIt()));

  // repositories — the Game Note API by default; the legacy Firestore
  // implementations stay selectable until the data cutover.
  if (useFirestore) {
    getIt.registerFactory<UserRepository>(() => UserRepositoryImpl());
    getIt.registerFactory<EsportGroupRepository>(
      () => EsportGroupRepositoryImpl(),
    );
    getIt.registerFactory<EsportLeagueRepository>(
      () => EsportLeagueRepositoryImpl(),
    );
    getIt.registerFactory<UserStatsRepository>(() => UserStatsRepositoryImpl());
    getIt.registerFactory<EsportGroupStatsRepository>(
      () => EsportGroupStatsRepositoryImpl(),
    );
  } else {
    getIt.registerFactory<UserRepository>(
      () => ApiUserRepository(client: getIt(), auth: getIt()),
    );
    getIt.registerFactory<EsportGroupRepository>(
      () => ApiEsportGroupRepository(client: getIt()),
    );
    getIt.registerFactory<EsportLeagueRepository>(
      () => ApiEsportLeagueRepository(client: getIt(), events: getIt()),
    );
    getIt.registerFactory<UserStatsRepository>(
      () => ApiUserStatsRepository(client: getIt()),
    );
    getIt.registerFactory<EsportGroupStatsRepository>(
      () => ApiEsportGroupStatsRepository(client: getIt()),
    );
  }

  getIt.registerSingleton(
    AppBloc(auth: getIt(), userRepository: getIt(), permissionUtil: getIt()),
  );

  // blocs
  getIt.registerFactory(() => SignInBloc());
  getIt.registerFactory<ThirdPartyBloc>(() => ThirdPartyBloc());
  getIt.registerFactory<ProfileBloc>(() => ProfileBloc(getIt()));

  getIt.registerFactory<GroupBloc>(() => GroupBloc(getIt()));
  getIt.registerFactory<TournamentBloc>(() => TournamentBloc(getIt()));
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      userStatsRepository: getIt(),
      auth: getIt(),
      cache: getIt(),
      userRepository: getIt(),
    ),
  );
  getIt.registerFactory<OngoingTournamentsBloc>(
    () => OngoingTournamentsBloc(getIt()),
  );

  getIt.registerFactory<UserBloc>(() => UserBloc(getIt()));

  getIt.registerFactory<ChangePasswordBloc>(() => ChangePasswordBloc(getIt()));
}
