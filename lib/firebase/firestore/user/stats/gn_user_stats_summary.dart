import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Per-user lifetime aggregate written by the `onLeagueMatchWritten` Cloud
/// Function. Single doc at `users/{uid}/stats/summary`. The dashboard reads
/// this directly so its load time is O(1) regardless of how many leagues
/// the user has joined.
class GNUserStatsSummary extends Equatable {
  final String userId;

  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goals;
  final int goalsConceded;

  final int tournamentsJoined;
  final int tournamentsFinished;
  final int championCount;
  final int runnerUpCount;
  final DateTime? lastChampionAt;

  final List<GNUserRecentMatch> recentMatches;
  final List<GNUserLeaguePerformance> leagueHistory;
  final List<GNUserOpponentStat> h2hSummary;

  final DateTime? updatedAt;
  final int schemaVersion;

  static const int kRecentMatchesCap = 20;
  static const int kLeagueHistoryCap = 20;
  static const int kCurrentSchemaVersion = 1;

  static const String subCollectionName = 'stats';
  static const String summaryDocId = 'summary';

  static const String fieldMatchesPlayed = 'matchesPlayed';
  static const String fieldWins = 'wins';
  static const String fieldDraws = 'draws';
  static const String fieldLosses = 'losses';
  static const String fieldGoals = 'goals';
  static const String fieldGoalsConceded = 'goalsConceded';
  static const String fieldTournamentsJoined = 'tournamentsJoined';
  static const String fieldTournamentsFinished = 'tournamentsFinished';
  static const String fieldChampionCount = 'championCount';
  static const String fieldRunnerUpCount = 'runnerUpCount';
  static const String fieldLastChampionAt = 'lastChampionAt';
  static const String fieldRecentMatches = 'recentMatches';
  static const String fieldLeagueHistory = 'leagueHistory';
  static const String fieldH2hSummary = 'h2hSummary';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldSchemaVersion = 'schemaVersion';

  const GNUserStatsSummary({
    required this.userId,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goals,
    required this.goalsConceded,
    required this.tournamentsJoined,
    required this.tournamentsFinished,
    required this.championCount,
    required this.runnerUpCount,
    required this.lastChampionAt,
    required this.recentMatches,
    this.leagueHistory = const [],
    this.h2hSummary = const [],
    required this.updatedAt,
    required this.schemaVersion,
  });

  factory GNUserStatsSummary.empty(String userId) {
    return GNUserStatsSummary(
      userId: userId,
      matchesPlayed: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      goals: 0,
      goalsConceded: 0,
      tournamentsJoined: 0,
      tournamentsFinished: 0,
      championCount: 0,
      runnerUpCount: 0,
      lastChampionAt: null,
      recentMatches: const [],
      leagueHistory: const [],
      h2hSummary: const [],
      updatedAt: null,
      schemaVersion: kCurrentSchemaVersion,
    );
  }

  factory GNUserStatsSummary.fromMap(Map<String, dynamic> map, String userId) {
    final rawRecent = map[fieldRecentMatches] as List<dynamic>? ?? const [];
    final recent = rawRecent
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => GNUserRecentMatch.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final rawHistory = map[fieldLeagueHistory] as List<dynamic>? ?? const [];
    final history = rawHistory
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (e) => GNUserLeaguePerformance.fromMap(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
    final rawH2H = map[fieldH2hSummary] as List<dynamic>? ?? const [];
    final h2h = rawH2H
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (e) => GNUserOpponentStat.fromMap(Map<String, dynamic>.from(e)),
        )
        .toList();
    return GNUserStatsSummary(
      userId: userId,
      matchesPlayed: (map[fieldMatchesPlayed] as num?)?.toInt() ?? 0,
      wins: (map[fieldWins] as num?)?.toInt() ?? 0,
      draws: (map[fieldDraws] as num?)?.toInt() ?? 0,
      losses: (map[fieldLosses] as num?)?.toInt() ?? 0,
      goals: (map[fieldGoals] as num?)?.toInt() ?? 0,
      goalsConceded: (map[fieldGoalsConceded] as num?)?.toInt() ?? 0,
      tournamentsJoined: (map[fieldTournamentsJoined] as num?)?.toInt() ?? 0,
      tournamentsFinished:
          (map[fieldTournamentsFinished] as num?)?.toInt() ?? 0,
      championCount: (map[fieldChampionCount] as num?)?.toInt() ?? 0,
      runnerUpCount: (map[fieldRunnerUpCount] as num?)?.toInt() ?? 0,
      lastChampionAt: tsToDate(map[fieldLastChampionAt]),
      recentMatches: recent,
      leagueHistory: history,
      h2hSummary: h2h,
      updatedAt: tsToDate(map[fieldUpdatedAt]),
      schemaVersion:
          (map[fieldSchemaVersion] as num?)?.toInt() ?? kCurrentSchemaVersion,
    );
  }

  // coverage:ignore-start
  // Firestore-side adapter — exercised via integration tests against the
  // emulator; covered indirectly by `fromMap` unit tests.
  factory GNUserStatsSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final userId = doc.reference.parent.parent?.id ?? doc.id;
    return GNUserStatsSummary.fromMap(data, userId);
  }
  // coverage:ignore-end

  Map<String, dynamic> toMap() {
    return {
      fieldMatchesPlayed: matchesPlayed,
      fieldWins: wins,
      fieldDraws: draws,
      fieldLosses: losses,
      fieldGoals: goals,
      fieldGoalsConceded: goalsConceded,
      fieldTournamentsJoined: tournamentsJoined,
      fieldTournamentsFinished: tournamentsFinished,
      fieldChampionCount: championCount,
      fieldRunnerUpCount: runnerUpCount,
      fieldLastChampionAt: lastChampionAt == null
          ? null
          : Timestamp.fromDate(lastChampionAt!),
      fieldRecentMatches: recentMatches.map((m) => m.toMap()).toList(),
      fieldLeagueHistory: leagueHistory.map((e) => e.toMap()).toList(),
      fieldH2hSummary: h2hSummary.map((e) => e.toMap()).toList(),
      fieldUpdatedAt: updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      fieldSchemaVersion: schemaVersion,
    };
  }

  double? get winRate => matchesPlayed == 0 ? null : wins / matchesPlayed;
  int get goalDifference => goals - goalsConceded;
  double? get championRate =>
      tournamentsFinished == 0 ? null : championCount / tournamentsFinished;
  double? get runnerUpRate =>
      tournamentsFinished == 0 ? null : runnerUpCount / tournamentsFinished;

  @override
  List<Object?> get props => [
    userId,
    matchesPlayed,
    wins,
    draws,
    losses,
    goals,
    goalsConceded,
    tournamentsJoined,
    tournamentsFinished,
    championCount,
    runnerUpCount,
    lastChampionAt,
    recentMatches,
    leagueHistory,
    h2hSummary,
    updatedAt,
    schemaVersion,
  ];
}

/// Compact head-to-head record vs one opponent, embedded in the summary so
/// the dashboard can render "đối đầu" rows without an extra subcollection
/// query.
class GNUserOpponentStat extends Equatable {
  final String opponentId;
  final String opponentDisplayName;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;

  const GNUserOpponentStat({
    required this.opponentId,
    required this.opponentDisplayName,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  factory GNUserOpponentStat.fromMap(Map<String, dynamic> map) {
    return GNUserOpponentStat(
      opponentId: map['opponentId'] as String? ?? '',
      opponentDisplayName: map['opponentDisplayName'] as String? ?? '',
      matchesPlayed: (map['matchesPlayed'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      draws: (map['draws'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'opponentId': opponentId,
    'opponentDisplayName': opponentDisplayName,
    'matchesPlayed': matchesPlayed,
    'wins': wins,
    'draws': draws,
    'losses': losses,
  };

  @override
  List<Object?> get props => [
    opponentId,
    opponentDisplayName,
    matchesPlayed,
    wins,
    draws,
    losses,
  ];
}

/// Performance snapshot for one league user joined. The cloud function
/// keeps a small array of these (cap [GNUserStatsSummary.kLeagueHistoryCap])
/// so the dashboard can chart trends without scanning raw matches.
class GNUserLeaguePerformance extends Equatable {
  final String leagueId;
  final String leagueName;
  final DateTime? lastPlayedAt;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goals;
  final int goalsConceded;

  const GNUserLeaguePerformance({
    required this.leagueId,
    required this.leagueName,
    required this.lastPlayedAt,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goals,
    required this.goalsConceded,
  });

  factory GNUserLeaguePerformance.fromMap(Map<String, dynamic> map) {
    return GNUserLeaguePerformance(
      leagueId: map['leagueId'] as String? ?? '',
      leagueName: map['leagueName'] as String? ?? '',
      lastPlayedAt: tsToDate(map['lastPlayedAt']),
      matchesPlayed: (map['matchesPlayed'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      draws: (map['draws'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      goals: (map['goals'] as num?)?.toInt() ?? 0,
      goalsConceded: (map['goalsConceded'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'leagueId': leagueId,
      'leagueName': leagueName,
      'lastPlayedAt':
          lastPlayedAt == null ? null : Timestamp.fromDate(lastPlayedAt!),
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'goals': goals,
      'goalsConceded': goalsConceded,
    };
  }

  /// Points-per-match. Returns null when the user has no finished matches in
  /// the league (avoids plotting a fake 0 on the chart).
  double? get pointsPerMatch =>
      matchesPlayed == 0 ? null : (wins * 3 + draws) / matchesPlayed;

  double? get goalDifferencePerMatch =>
      matchesPlayed == 0 ? null : (goals - goalsConceded) / matchesPlayed;

  @override
  List<Object?> get props => [
    leagueId,
    leagueName,
    lastPlayedAt,
    matchesPlayed,
    wins,
    draws,
    losses,
    goals,
    goalsConceded,
  ];
}

/// Result of a single match from one user's perspective. Stored inline in
/// the summary doc so the dashboard can render the recent-matches list
/// without joining matches/leagues.
enum GNRecentMatchResult { win, draw, loss }

class GNUserRecentMatch extends Equatable {
  final String matchId;
  final String leagueId;
  final String leagueName;
  final DateTime date;
  final int userScore;
  final int opponentScore;
  final String opponentId;
  final String opponentDisplayName;
  final GNRecentMatchResult result;
  // When this match was last edited. Used by the dashboard to surface
  // recently-updated matches even if their play date is older.
  final DateTime? updatedAt;

  const GNUserRecentMatch({
    required this.matchId,
    required this.leagueId,
    required this.leagueName,
    required this.date,
    required this.userScore,
    required this.opponentScore,
    required this.opponentId,
    required this.opponentDisplayName,
    required this.result,
    this.updatedAt,
  });

  factory GNUserRecentMatch.fromMap(Map<String, dynamic> map) {
    return GNUserRecentMatch(
      matchId: map['matchId'] as String? ?? '',
      leagueId: map['leagueId'] as String? ?? '',
      leagueName: map['leagueName'] as String? ?? '',
      date: tsToDate(map['date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      userScore: (map['userScore'] as num?)?.toInt() ?? 0,
      opponentScore: (map['opponentScore'] as num?)?.toInt() ?? 0,
      opponentId: map['opponentId'] as String? ?? '',
      opponentDisplayName: map['opponentDisplayName'] as String? ?? 'Đối thủ',
      result: _resultFromString(map['result'] as String?),
      updatedAt: tsToDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'leagueId': leagueId,
      'leagueName': leagueName,
      'date': Timestamp.fromDate(date),
      'userScore': userScore,
      'opponentScore': opponentScore,
      'opponentId': opponentId,
      'opponentDisplayName': opponentDisplayName,
      'result': _resultToString(result),
      'updatedAt':
          updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  @override
  List<Object?> get props => [
    matchId,
    leagueId,
    leagueName,
    date,
    userScore,
    opponentScore,
    opponentId,
    opponentDisplayName,
    result,
    updatedAt,
  ];
}

DateTime? tsToDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

GNRecentMatchResult _resultFromString(String? raw) {
  switch (raw) {
    case 'win':
      return GNRecentMatchResult.win;
    case 'loss':
      return GNRecentMatchResult.loss;
    case 'draw':
    default:
      return GNRecentMatchResult.draw;
  }
}

String _resultToString(GNRecentMatchResult r) {
  switch (r) {
    case GNRecentMatchResult.win:
      return 'win';
    case GNRecentMatchResult.draw:
      return 'draw';
    case GNRecentMatchResult.loss:
      return 'loss';
  }
}
