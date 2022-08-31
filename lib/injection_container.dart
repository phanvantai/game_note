import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/data/datasources/local/league_local_datasource.dart';
import 'package:game_note/data/datasources/local/match_local_datasource.dart';
import 'package:game_note/data/datasources/local/player_stats_local_datasource.dart';
import 'package:game_note/data/datasources/local/round_local_datasource.dart';
import 'package:game_note/data/repositories/league_repository_impl.dart';
import 'package:game_note/data/repositories/match_repository_impl.dart';
import 'package:game_note/data/repositories/player_stats_repository_impl.dart';
import 'package:game_note/data/repositories/round_repository_impl.dart';
import 'package:game_note/domain/repositories/league_repository.dart';
import 'package:game_note/domain/repositories/match_repository.dart';
import 'package:game_note/domain/repositories/player_stats_repository.dart';
import 'package:game_note/domain/repositories/round_repository.dart';
import 'package:game_note/domain/usecases/create_league.dart';
import 'package:game_note/domain/usecases/create_match.dart';
import 'package:game_note/domain/usecases/create_player_stats.dart';
import 'package:game_note/domain/usecases/create_round.dart';
import 'package:game_note/domain/usecases/get_league.dart';
import 'package:game_note/domain/usecases/get_leagues.dart';
import 'package:game_note/domain/usecases/get_matches.dart';
import 'package:game_note/domain/usecases/get_player_stats.dart';
import 'package:game_note/domain/usecases/get_rounds.dart';
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
  getIt.registerSingleton<RoundLocalDatasource>(
      RoundLocalDatasourceImpl(getIt()));
  getIt.registerSingleton<MatchLocalDatasource>(
      MatchLocalDatasourceImpl(getIt()));

  // repositories
  getIt.registerSingleton<LeagueRepository>(LeagueRepositoryImpl(getIt()));
  getIt.registerSingleton<PlayerStatsRepository>(
      PlayerStatsRepositoryImpl(getIt()));
  getIt.registerSingleton<RoundRepository>(RoundRepositoryImpl(getIt()));
  getIt.registerSingleton<MatchRepository>(MatchRepositoryImpl(getIt()));

  // usecases
  getIt.registerSingleton(GetLeagues(getIt()));
  getIt.registerSingleton(CreateLeague(getIt()));
  getIt.registerSingleton(GetLeague(getIt()));

  getIt.registerSingleton(CreatePlayerStats(getIt()));
  getIt.registerSingleton(GetPlayerStats(getIt()));
  getIt.registerSingleton(UpdatePlayerStats(getIt()));

  getIt.registerSingleton(CreateRound(getIt()));
  getIt.registerSingleton(GetRounds(getIt()));

  getIt.registerSingleton(CreateMatch(getIt()));
  getIt.registerSingleton(GetMatches(getIt()));
}
