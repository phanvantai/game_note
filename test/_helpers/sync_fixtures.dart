import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/offline/domain/entities/league_model.dart';
import 'package:pes_arena/offline/domain/entities/match_model.dart';
import 'package:pes_arena/offline/domain/entities/player_model.dart';
import 'package:pes_arena/offline/domain/entities/player_stats_model.dart';
import 'package:pes_arena/offline/domain/entities/result_model.dart';
import 'package:pes_arena/offline/domain/entities/round_model.dart';

PlayerModel offlinePlayer(int id, String name) =>
    PlayerModel(id: id, fullname: name);

PlayerStatsModel offlineStats(int playerId, String name, int leagueId) =>
    PlayerStatsModel(
      playerModel: offlinePlayer(playerId, name),
      leagueId: leagueId,
    );

MatchModel offlineMatch({
  required int matchId,
  required int roundId,
  required PlayerModel home,
  required PlayerModel away,
  int? homeScore,
  int? awayScore,
  bool finished = true,
  String? created,
}) {
  return MatchModel(
    id: matchId,
    roundId: roundId,
    status: finished,
    created: created,
    home: ResultModel(matchId: matchId, playerModel: home, score: homeScore),
    away: ResultModel(matchId: matchId, playerModel: away, score: awayScore),
  );
}

LeagueModel offlineLeagueFixture({
  int id = 1,
  String name = 'Giải mùa hè',
  DateTime? dateTime,
  required List<PlayerModel> players,
  required List<List<MatchModel>> roundsMatches,
}) {
  final stats = [
    for (final p in players) PlayerStatsModel(playerModel: p, leagueId: id),
  ];
  final rounds = [
    for (var i = 0; i < roundsMatches.length; i++)
      RoundModel(id: i + 1, leagueId: id, matches: roundsMatches[i]),
  ];
  return LeagueModel(
    id: id,
    name: name,
    dateTime: dateTime ?? DateTime(2024, 1, 1),
    players: stats,
    rounds: rounds,
  );
}

GNUser onlineUser(
  String id, {
  String? displayName,
  bool isPlaceholder = false,
}) => GNUser(
  id: id,
  displayName: displayName ?? id,
  phoneNumber: null,
  email: null,
  photoUrl: null,
  role: 'user',
  fcmToken: '',
  isPlaceholder: isPlaceholder,
);

GNEsportGroup onlineGroup(
  String id, {
  String groupName = 'Group',
  List<String> members = const [],
  String ownerId = 'owner',
}) => GNEsportGroup(
  id: id,
  groupName: groupName,
  ownerId: ownerId,
  members: members,
  description: '',
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
  status: 'active',
);
