import 'package:game_note/features/offline/data/database/database_manager.dart';
import 'package:game_note/features/community/data/datasources/auth_datasource.dart';
import 'package:game_note/features/community/data/repositories/auth_repository_impl.dart';
import 'package:game_note/features/community/domain/repositories/auth_repository.dart';
import 'package:game_note/features/community/domain/usecases/sign_in_with_email.dart';
import 'package:game_note/features/community/presentation/auth/sign_in/bloc/sign_in_bloc.dart';
import 'package:game_note/features/community/presentation/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:game_note/features/offline/data/datasources/league_local_datasource.dart';
import 'package:game_note/features/offline/data/repositories/league_repository_impl.dart';
import 'package:game_note/features/offline/domain/repositories/league_repository.dart';
import 'package:game_note/features/offline/domain/usecases/create_league.dart';
import 'package:game_note/features/offline/domain/usecases/create_rounds.dart';
import 'package:game_note/features/offline/domain/usecases/delete_league.dart';
import 'package:game_note/features/offline/domain/usecases/get_league.dart';
import 'package:game_note/features/offline/domain/usecases/get_leagues.dart';
import 'package:game_note/features/offline/domain/usecases/set_players_for_league.dart';
import 'package:game_note/features/offline/domain/usecases/update_match.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/helpers/shared_preferences_helper.dart';
import 'features/community/domain/usecases/sign_up_with_email.dart';
import 'features/offline/data/models/league_manager.dart';
import 'features/offline/presentation/league/league_detail/bloc/league_detail_bloc.dart';

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

  getIt.registerFactory(() => AuthDatasource());

  // repositories
  getIt.registerSingleton<LeagueRepository>(LeagueRepositoryImpl(getIt()));

  getIt.registerFactory<AuthRepository>(() => AuthRepositoryImpl(getIt()));

  // usecases
  getIt.registerSingleton(GetLeagues(getIt()));
  getIt.registerSingleton(CreateLeague(getIt()));
  getIt.registerSingleton(GetLeague(getIt()));
  getIt.registerSingleton(DeleteLeague(getIt()));

  getIt.registerSingleton(SetPlayersForLeague(getIt()));
  getIt.registerSingleton(CreateRounds(getIt()));
  getIt.registerSingleton(UpdateMatch(getIt()));

  getIt.registerFactory(() => SignInWithEmail(getIt()));
  getIt.registerFactory(() => SignUpWithEmail(getIt()));

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

  getIt.registerFactory(() => SignInBloc(signInWithEmail: getIt()));
  getIt.registerFactory(() => SignUpBloc(signUpWithEmail: getIt()));
}
