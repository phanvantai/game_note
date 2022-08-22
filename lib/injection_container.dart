import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/data/datasources/local/league_local_datasource.dart';
import 'package:game_note/data/repositories/league_repository_impl.dart';
import 'package:game_note/domain/repositories/league_repository.dart';
import 'package:game_note/domain/usecases/get_leagues.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  getIt.registerSingleton(DatabaseManager());

  // bloc
  //getIt.registerFactory<LeagueListBloc>(() => LeagueListBloc(getLeagues: getLeagues))

  // datasources
  getIt.registerSingleton<LeagueLocalDatasource>(
      LeagueLocalDatasourceImpl(getIt()));

  // repositories
  getIt.registerSingleton<LeagueRepository>(LeagueRepositoryImpl(getIt()));

  // usecases
  getIt.registerSingleton(GetLeagues(getIt()));
}
