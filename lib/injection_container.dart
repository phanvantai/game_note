import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/data/datasources/local/league_local_datasource.dart';
import 'package:game_note/data/repositories/league_repository_impl.dart';
import 'package:game_note/domain/repositories/league_repository.dart';
import 'package:game_note/domain/usecases/create_league.dart';
import 'package:game_note/domain/usecases/create_rounds.dart';
import 'package:game_note/domain/usecases/get_league.dart';
import 'package:game_note/domain/usecases/get_leagues.dart';
import 'package:game_note/domain/usecases/set_players_for_league.dart';
import 'package:game_note/data/models/league_manager.dart';
import 'package:game_note/domain/usecases/update_match.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/helpers/shared_preferences_helper.dart';
import 'presentation/features/offline/league/league_detail/bloc/league_detail_bloc.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  getIt.registerSingletonAsync<SharedPreferences>(
      () => SharedPreferences.getInstance());
  getIt.registerSingleton(
      SharedPreferencesHelper(await getIt.getAsync<SharedPreferences>()));

  getIt.registerSingleton(DatabaseManager());

  getIt.registerSingleton(LeagueManager(getIt()));

  // bloc
  //getIt.registerFactory<LeagueListBloc>(() => LeagueListBloc(getLeagues: getLeagues))
  getIt.registerFactory<LeagueDetailBloc>(() => LeagueDetailBloc(
        getLeague: getIt(),
        setPlayersForLeague: getIt(),
        createRounds: getIt(),
        updateMatch: getIt(),
      ));

  // datasources
  getIt.registerSingleton<LeagueLocalDatasource>(
      LeagueLocalDatasourceImpl(getIt()));

  // repositories
  getIt.registerSingleton<LeagueRepository>(LeagueRepositoryImpl(getIt()));

  // usecases
  getIt.registerSingleton(GetLeagues(getIt()));
  getIt.registerSingleton(CreateLeague(getIt()));
  getIt.registerSingleton(GetLeague(getIt()));

  getIt.registerSingleton(SetPlayersForLeague(getIt()));
  getIt.registerSingleton(CreateRounds(getIt()));
  getIt.registerSingleton(UpdateMatch(getIt()));
}
