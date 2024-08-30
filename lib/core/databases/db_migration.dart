// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:game_note/offline/data/database/database_manager.dart';
// import 'package:game_note/offline/data/database/league_manager.dart';
// import 'package:game_note/offline/data/database/match_manager.dart';
// import 'package:game_note/offline/data/database/player_stats_manager.dart';
// import 'package:game_note/offline/data/database/result_manager.dart';
// import 'package:game_note/offline/data/database/round_manager.dart';
// import 'package:game_note/offline/domain/entities/player_model.dart';
// import 'package:game_note/offline/domain/entities/result_model.dart';

// import '../../offline/domain/entities/league_model.dart';
// import '../../offline/domain/entities/match_model.dart';
// import '../../offline/domain/entities/player_stats_model.dart';
// import '../../offline/domain/entities/round_model.dart';
// import '../../injection_container.dart';

// class DbMigration {
//   final firestore = FirebaseFirestore.instance;

//   Future<void> migrateFromLocalToCloud() async {
//     final dbManager = getIt<DatabaseManager>();
//     await dbManager.open();
//     await _migratePlayer(dbManager);
//     await _migrateLeagues(dbManager);
//   }

//   Future<void> _migratePlayer(DatabaseManager dbManager) async {
//     final List<PlayerModel> players = await dbManager.players();
//     for (var player in players) {
//       await firestore.collection(GNCollection.player).add(player.toMap());
//     }
//   }

//   Future<void> _migrateLeagues(DatabaseManager dbManager) async {
//     final List<LeagueModel> leagues = await dbManager.getLeagues();
//     for (var league in leagues) {
//       await firestore.collection(GNCollection.league).add(league.toMap());
//       if (league.id != null) {
//         _migrateRound(league.id!);
//         _migrateLeaguePlayers(league.id!);
//       }
//     }
//   }

//   Future<void> _migrateRound(int leagueId) async {
//     final List<RoundModel> rounds =
//         await getIt<DatabaseManager>().getRounds(leagueId);
//     for (var round in rounds) {
//       await firestore.collection(GNCollection.round).add(round.toMap());
//       if (round.id != null) {
//         _migrateMatch(round.id!);
//       }
//     }
//   }

//   Future<void> _migrateMatch(int roundId) async {
//     final List<MatchModel> matches =
//         await getIt<DatabaseManager>().getMatches(roundId);
//     for (var match in matches) {
//       await firestore.collection(GNCollection.match).add(match.toMap());
//       if (match.id != null) {
//         _migrateResult(match.id!);
//       }
//     }
//   }

//   Future<void> _migrateResult(int matchId) async {
//     final List<ResultModel> matches =
//         await getIt<DatabaseManager>().getResults(matchId);
//     for (var match in matches) {
//       await firestore.collection(GNCollection.matchResult).add(match.toMap());
//     }
//   }

//   Future<void> _migrateLeaguePlayers(int leagueId) async {
//     final List<PlayerStatsModel> players =
//         await getIt<DatabaseManager>().getPlayerStats(leagueId);
//     for (var player in players) {
//       await firestore.collection(GNCollection.leaguePlayer).add(player.toMap());
//     }
//   }
// }
