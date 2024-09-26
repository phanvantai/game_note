import 'package:game_note/offline/data/database/database_manager.dart';
import 'package:game_note/offline/data/datasources/league_local_datasource.dart';
import 'package:game_note/offline/data/repositories/league_repository_impl.dart';
import 'package:game_note/offline/domain/repositories/league_repository.dart';
import 'package:game_note/offline/domain/usecases/create_league.dart';
import 'package:game_note/offline/domain/usecases/create_rounds.dart';
import 'package:game_note/offline/domain/usecases/delete_league.dart';
import 'package:game_note/offline/domain/usecases/get_league.dart';
import 'package:game_note/offline/domain/usecases/get_leagues.dart';
import 'package:game_note/offline/domain/usecases/set_players_for_league.dart';
import 'package:game_note/offline/domain/usecases/update_match.dart';
import 'package:game_note/presentation/profile/change_password/bloc/change_password_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/helpers/shared_preferences_helper.dart';
import 'data/repositories/esport/esport_group_repository_impl.dart';
import 'data/repositories/esport/esport_league_repository_impl.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'data/repositories/team_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'domain/repositories/esport/esport_group_repository.dart';
import 'domain/repositories/esport/esport_league_repository.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/repositories/team_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'firebase/firestore/gn_firestore.dart';
import 'firebase/messaging/gn_firebase_messaging.dart';
import 'firebase/storage/gn_storage.dart';
import 'presentation/app/bloc/app_bloc.dart';
import 'presentation/auth/sign_in/bloc/sign_in_bloc.dart';
import 'presentation/auth/third_party/bloc/third_party_bloc.dart';
import 'offline/data/models/league_manager.dart';
import 'offline/presentation/league_detail/bloc/league_detail_bloc.dart';
import 'firebase/auth/gn_auth.dart';
import 'presentation/esport/bloc/esport_bloc.dart';
import 'presentation/esport/groups/bloc/group_bloc.dart';
import 'presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'presentation/notification/bloc/notification_bloc.dart';
import 'presentation/profile/bloc/profile_bloc.dart';
import 'presentation/team/bloc/teams_bloc.dart';
import 'presentation/users/bloc/user_bloc.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  getIt.registerSingletonAsync<SharedPreferences>(
      () => SharedPreferences.getInstance());
  getIt.registerSingleton(
      SharedPreferencesHelper(await getIt.getAsync<SharedPreferences>()));

  getIt.registerSingleton(DatabaseManager());

  getIt.registerSingleton(LeagueManager(getIt()));

  // datasources
  getIt.registerSingleton<LeagueLocalDatasource>(
      LeagueLocalDatasourceImpl(getIt()));

  // repositories
  getIt.registerSingleton<LeagueRepository>(LeagueRepositoryImpl(getIt()));

  // usecases
  getIt.registerSingleton(GetLeagues(getIt()));
  getIt.registerSingleton(CreateLeague(getIt()));
  getIt.registerSingleton(GetLeague(getIt()));
  getIt.registerSingleton(DeleteLeague(getIt()));

  getIt.registerSingleton(SetPlayersForLeague(getIt()));
  getIt.registerSingleton(CreateRounds(getIt()));
  getIt.registerSingleton(UpdateMatch(getIt()));

  // bloc
  //getIt.registerFactory<LeagueListBloc>(() => LeagueListBloc(getLeagues: getLeagues))
  getIt.registerFactory<LeagueDetailBloc>(
    () => LeagueDetailBloc(
      getLeague: getIt(),
      setPlayersForLeague: getIt(),
      createRounds: getIt(),
      updateMatch: getIt(),
    ),
  );

  getIt.registerSingleton(AppBloc());

  // firebase service
  getIt.registerSingleton(GNAuth());
  getIt.registerSingleton(GNFirestore());
  getIt.registerSingleton(GNStorage());
  getIt.registerSingleton(GNFirebaseMessaging());

  /// online mode
  // data
  // repositories
  getIt.registerFactory<UserRepository>(() => UserRepositoryImpl());
  getIt.registerFactory<TeamRepository>(() => TeamRepositoryImpl());
  getIt.registerFactory<EsportGroupRepository>(
      () => EsportGroupRepositoryImpl());
  getIt.registerFactory<EsportLeagueRepository>(
      () => EsportLeagueRepositoryImpl());
  getIt.registerFactory<NotificationRepository>(
      () => NotificationRepositoryImpl());
  // blocs
  getIt.registerFactory(() => SignInBloc());
  getIt.registerFactory<ThirdPartyBloc>(() => ThirdPartyBloc());
  getIt.registerFactory<ProfileBloc>(() => ProfileBloc(getIt()));

  getIt.registerFactory<TeamsBloc>(() => TeamsBloc(getIt()));

  getIt.registerFactory<EsportBloc>(() => EsportBloc());
  getIt.registerFactory<GroupBloc>(() => GroupBloc(getIt()));
  getIt.registerFactory<TournamentBloc>(() => TournamentBloc(getIt()));

  getIt.registerFactory<UserBloc>(() => UserBloc(getIt()));
  getIt.registerFactory<NotificationBloc>(() => NotificationBloc(getIt()));

  getIt.registerFactory<ChangePasswordBloc>(() => ChangePasswordBloc(getIt()));
}
