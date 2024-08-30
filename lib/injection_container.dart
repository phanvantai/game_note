import 'package:game_note/firebase/firestore/gn_firestore.dart';
import 'package:game_note/presentation/app/bloc/app_bloc.dart';
import 'package:game_note/offline/data/database/database_manager.dart';
import 'package:game_note/presentation/auth/sign_in/bloc/sign_in_bloc.dart';
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
import 'package:game_note/presentation/profile/bloc/profile_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/helpers/shared_preferences_helper.dart';
import 'presentation/auth/third_party/bloc/third_party_bloc.dart';
import 'offline/data/models/league_manager.dart';
import 'offline/presentation/league_detail/bloc/league_detail_bloc.dart';
import 'firebase/auth/gn_auth.dart';

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

  getIt.registerFactory(() => SignInBloc());

  getIt.registerFactory<ThirdPartyBloc>(() => ThirdPartyBloc());

  getIt.registerFactory<ProfileBloc>(() => ProfileBloc());

  getIt.registerSingleton(AppBloc());

  // firebase service
  getIt.registerSingleton(GNAuth());
  getIt.registerSingleton(GNFirestore());
}
