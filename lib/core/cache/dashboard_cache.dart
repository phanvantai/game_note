import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/home/dashboard/models/dashboard_stats.dart';
import '../../presentation/home/dashboard/models/league_performance_point.dart';
import '../../presentation/home/dashboard/models/opponent_stat.dart';
import '../../presentation/home/dashboard/models/recent_match_summary.dart';

/// Local cache for the dashboard so opening Home renders instantly while a
/// fresh fetch happens in the background.
///
/// Keyed per-user so logging out and back in as a different account doesn't
/// flash someone else's stats.
class DashboardCache {
  final SharedPreferences _prefs;

  DashboardCache(this._prefs);

  static const String _keyPrefix = 'dashboard_cache_v1_';

  String _key(String uid) => '$_keyPrefix$uid';

  Future<DashboardStats?> read(String uid) async {
    final raw = _prefs.getString(_key(uid));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _statsFromJson(map);
    } catch (_) {
      // Corrupt entry — drop it and return miss. Don't surface an error to
      // the caller; cache is best-effort.
      await _prefs.remove(_key(uid));
      return null;
    }
  }

  Future<void> write(String uid, DashboardStats stats) async {
    final encoded = jsonEncode(_statsToJson(stats));
    await _prefs.setString(_key(uid), encoded);
  }

  Future<void> clear(String uid) async {
    await _prefs.remove(_key(uid));
  }
}

Map<String, dynamic> _statsToJson(DashboardStats stats) => {
  'tournamentsJoined': stats.tournamentsJoined,
  'finishedTournaments': stats.finishedTournaments,
  'championCount': stats.championCount,
  'runnerUpCount': stats.runnerUpCount,
  'lastChampionAt': stats.lastChampionAt?.millisecondsSinceEpoch,
  'wins': stats.wins,
  'draws': stats.draws,
  'losses': stats.losses,
  'matchesPlayed': stats.matchesPlayed,
  'goals': stats.goals,
  'goalsConceded': stats.goalsConceded,
  'recentMatches': stats.recentMatches.map(_recentToJson).toList(),
  'leaguePerformance':
      stats.leaguePerformance.map(_perfToJson).toList(),
  'opponents': stats.opponents.map(_opponentToJson).toList(),
};

DashboardStats _statsFromJson(Map<String, dynamic> map) {
  final ts = map['lastChampionAt'] as int?;
  final recentRaw = map['recentMatches'] as List<dynamic>? ?? const [];
  final perfRaw = map['leaguePerformance'] as List<dynamic>? ?? const [];
  final oppRaw = map['opponents'] as List<dynamic>? ?? const [];
  return DashboardStats(
    tournamentsJoined: (map['tournamentsJoined'] as num?)?.toInt() ?? 0,
    finishedTournaments: (map['finishedTournaments'] as num?)?.toInt() ?? 0,
    championCount: (map['championCount'] as num?)?.toInt() ?? 0,
    runnerUpCount: (map['runnerUpCount'] as num?)?.toInt() ?? 0,
    lastChampionAt: ts == null ? null : DateTime.fromMillisecondsSinceEpoch(ts),
    wins: (map['wins'] as num?)?.toInt() ?? 0,
    draws: (map['draws'] as num?)?.toInt() ?? 0,
    losses: (map['losses'] as num?)?.toInt() ?? 0,
    matchesPlayed: (map['matchesPlayed'] as num?)?.toInt() ?? 0,
    goals: (map['goals'] as num?)?.toInt() ?? 0,
    goalsConceded: (map['goalsConceded'] as num?)?.toInt() ?? 0,
    recentMatches: recentRaw
        .whereType<Map>()
        .map((e) => _recentFromJson(Map<String, dynamic>.from(e)))
        .toList(),
    leaguePerformance: perfRaw
        .whereType<Map>()
        .map((e) => _perfFromJson(Map<String, dynamic>.from(e)))
        .toList(),
    opponents: oppRaw
        .whereType<Map>()
        .map((e) => _opponentFromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

Map<String, dynamic> _opponentToJson(OpponentStat o) => {
  'opponentId': o.opponentId,
  'opponentDisplayName': o.opponentDisplayName,
  'matchesPlayed': o.matchesPlayed,
  'wins': o.wins,
  'draws': o.draws,
  'losses': o.losses,
};

OpponentStat _opponentFromJson(Map<String, dynamic> map) => OpponentStat(
  opponentId: map['opponentId'] as String? ?? '',
  opponentDisplayName: map['opponentDisplayName'] as String? ?? '',
  matchesPlayed: (map['matchesPlayed'] as num?)?.toInt() ?? 0,
  wins: (map['wins'] as num?)?.toInt() ?? 0,
  draws: (map['draws'] as num?)?.toInt() ?? 0,
  losses: (map['losses'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _perfToJson(LeaguePerformancePoint p) => {
  'leagueId': p.leagueId,
  'leagueName': p.leagueName,
  'lastPlayedAt': p.lastPlayedAt?.millisecondsSinceEpoch,
  'matchesPlayed': p.matchesPlayed,
  'wins': p.wins,
  'draws': p.draws,
  'losses': p.losses,
  'ppm': p.pointsPerMatch,
  'gdpm': p.goalDifferencePerMatch,
};

LeaguePerformancePoint _perfFromJson(Map<String, dynamic> map) {
  final lp = map['lastPlayedAt'] as int?;
  return LeaguePerformancePoint(
    leagueId: map['leagueId'] as String? ?? '',
    leagueName: map['leagueName'] as String? ?? '',
    lastPlayedAt: lp == null ? null : DateTime.fromMillisecondsSinceEpoch(lp),
    matchesPlayed: (map['matchesPlayed'] as num?)?.toInt() ?? 0,
    wins: (map['wins'] as num?)?.toInt() ?? 0,
    draws: (map['draws'] as num?)?.toInt() ?? 0,
    losses: (map['losses'] as num?)?.toInt() ?? 0,
    pointsPerMatch: (map['ppm'] as num?)?.toDouble(),
    goalDifferencePerMatch: (map['gdpm'] as num?)?.toDouble(),
  );
}

Map<String, dynamic> _recentToJson(RecentMatchSummary m) => {
  'matchId': m.matchId,
  'leagueId': m.leagueId,
  'leagueName': m.leagueName,
  'date': m.date.millisecondsSinceEpoch,
  'userScore': m.userScore,
  'opponentScore': m.opponentScore,
  'opponentDisplayName': m.opponentDisplayName,
  'result': m.result.name,
};

RecentMatchSummary _recentFromJson(Map<String, dynamic> map) {
  return RecentMatchSummary(
    matchId: map['matchId'] as String? ?? '',
    leagueId: map['leagueId'] as String? ?? '',
    leagueName: map['leagueName'] as String? ?? '',
    date: DateTime.fromMillisecondsSinceEpoch(
      (map['date'] as num?)?.toInt() ?? 0,
    ),
    userScore: (map['userScore'] as num?)?.toInt() ?? 0,
    opponentScore: (map['opponentScore'] as num?)?.toInt() ?? 0,
    opponentDisplayName: map['opponentDisplayName'] as String? ?? 'Đối thủ',
    result: MatchResult.values.firstWhere(
      (r) => r.name == map['result'],
      orElse: () => MatchResult.draw,
    ),
  );
}
