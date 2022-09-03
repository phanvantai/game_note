import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/core/database/league_manager.dart';
import 'package:game_note/core/database/match_manager.dart';
import 'package:game_note/core/database/player_stats_manager.dart';
import 'package:game_note/core/database/result_manager.dart';
import 'package:game_note/core/database/round_manager.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';
import 'package:game_note/domain/entities/result_model.dart';
import 'package:game_note/domain/entities/round_model.dart';
import 'package:game_note/presentation/models/tournament_helper.dart';

class LeagueManager {
  final DatabaseManager databaseManager;

  LeagueManager(this.databaseManager);

  late LeagueModel _leagueModel;
  late List<PlayerModel> _players;

  LeagueModel get league => _leagueModel;

  setLeague(LeagueModel leagueModel) async {
    _leagueModel = leagueModel;
    setPlayers(_leagueModel.players.map((e) => e.playerModel).toList());
    print(_leagueModel);
  }

  List<PlayerModel> get players => _players;

  setPlayers(List<PlayerModel> players) async {
    _players = players;
  }

  getLeague(int id) async {
    var abc = await databaseManager.getLeague(id);
    if (abc != null) {
      await setLeague(abc);
    }
  }

  addPlayersToLeague() async {
    List<PlayerStatsModel> playersStats = [];
    for (var player in _players) {
      var model =
          PlayerStatsModel(playerModel: player, leagueId: _leagueModel.id!);
      var id = await databaseManager.createPlayerStats(model);
      playersStats.add(model.copyWith(id: id));
    }
    await setLeague(league.copyWith(players: playersStats));
  }

  createRounds() async {
    //
    var listMaps = TournamentHelper.createRounds(
      players,
      PlayerModel.virtualPlayer,
    );
    List<RoundModel> rounds = [];
    for (var list in listMaps) {
      // create round
      var round = RoundModel(leagueId: league.id!);
      var roundId = await databaseManager.createRound(round);
      round = round.copyWith(id: roundId);

      // create matches
      List<MatchModel> matches = [];
      print('------------------------------------------------------------');
      for (var map in list) {
        print('==========================================================');
        // create match
        var match = MatchModel(roundId: roundId);
        var matchId = await databaseManager.createMatch(match);
        match = match.copyWith(id: matchId);

        // create result home
        var resultHome =
            ResultModel(matchId: matchId, playerModel: map.keys.first);
        var resultHomeId = await databaseManager.createResult(resultHome);
        resultHome = resultHome.copyWith(id: resultHomeId);
        print(resultHome);

        // create result away
        var resultAway =
            ResultModel(matchId: matchId, playerModel: map.values.first);
        var resultAwayId = await databaseManager.createResult(resultAway);
        resultAway = resultAway.copyWith(id: resultAwayId);
        print(resultAway);

        match.copyWith(
          home: resultHome,
          away: resultAway,
          created: DateTime.now().toString(),
        );
        matches.add(match);
        print('==========================================================');
      }

      round.copyWith(matches: matches);

      rounds.add(round);
      print('////////////////////////////////////////////////////////////');
    }

    setLeague(league.copyWith(rounds: rounds));
  }
}
