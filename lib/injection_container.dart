import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/data/datasources/local/league_local_datasource.dart';
import 'package:game_note/data/datasources/local/player_stats_local_datasource.dart';
import 'package:game_note/data/repositories/league_repository_impl.dart';
import 'package:game_note/data/repositories/player_stats_repository_impl.dart';
import 'package:game_note/domain/repositories/league_repository.dart';
import 'package:game_note/domain/repositories/player_stats_repository.dart';
import 'package:game_note/domain/usecases/create_league.dart';
import 'package:game_note/domain/usecases/create_player_stats.dart';
import 'package:game_note/domain/usecases/get_league.dart';
import 'package:game_note/domain/usecases/get_leagues.dart';
import 'package:game_note/domain/usecases/get_player_stats.dart';
import 'package:game_note/domain/usecases/update_player_stats.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  getIt.registerSingleton(DatabaseManager());

  // bloc
  //getIt.registerFactory<LeagueListBloc>(() => LeagueListBloc(getLeagues: getLeagues))

  // datasources
  getIt.registerSingleton<LeagueLocalDatasource>(
      LeagueLocalDatasourceImpl(getIt()));
  getIt.registerSingleton<PlayerStatsLocalDatasource>(
      PlayerStatsLocalDatasourceImpl(getIt()));

  // repositories
  getIt.registerSingleton<LeagueRepository>(LeagueRepositoryImpl(getIt()));
  getIt.registerSingleton<PlayerStatsRepository>(
      PlayerStatsRepositoryImpl(getIt()));

  // usecases
  getIt.registerSingleton(GetLeagues(getIt()));
  getIt.registerSingleton(CreateLeague(getIt()));
  getIt.registerSingleton(GetLeague(getIt()));
  getIt.registerSingleton(CreatePlayerStats(getIt()));
  getIt.registerSingleton(GetPlayerStats(getIt()));
  getIt.registerSingleton(UpdatePlayerStats(getIt()));
}
