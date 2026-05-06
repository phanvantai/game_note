import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Per-group lifetime aggregate written by the `onLeagueMatchWritten` /
/// `onLeagueStatusChanged` / `onEsportLeagueWritten` Cloud Functions.
///
/// Single doc at `esports_groups/{groupId}/stats/summary`. The Tổng quan
/// tab reads this directly so its load time is O(1) regardless of how
/// many leagues the group has played. Awards (vô đối / kẻ về nhì /
/// hoà vương / hàng thủ thép / cao thủ) are derived client-side from
/// `playerStats` so threshold tweaks don't require a function redeploy.
class GNEsportGroupStatsSummary extends Equatable {
  final String groupId;
  final int totalLeagues;
  final int finishedLeagues;
  final List<GNEsportGroupPlayerEntry> playerStats;
  final DateTime? updatedAt;
  final int schemaVersion;

  static const int kCurrentSchemaVersion = 1;

  static const String subCollectionName = 'stats';
  static const String summaryDocId = 'summary';
  static const String recomputeRequestDocId = '_recompute_request';

  static const String fieldTotalLeagues = 'totalLeagues';
  static const String fieldFinishedLeagues = 'finishedLeagues';
  static const String fieldPlayerStats = 'playerStats';
  static const String fieldSchemaVersion = 'schemaVersion';
  static const String fieldUpdatedAt = 'updatedAt';

  const GNEsportGroupStatsSummary({
    required this.groupId,
    required this.totalLeagues,
    required this.finishedLeagues,
    required this.playerStats,
    required this.updatedAt,
    required this.schemaVersion,
  });

  factory GNEsportGroupStatsSummary.empty(String groupId) {
    return GNEsportGroupStatsSummary(
      groupId: groupId,
      totalLeagues: 0,
      finishedLeagues: 0,
      playerStats: const [],
      updatedAt: null,
      schemaVersion: kCurrentSchemaVersion,
    );
  }

  factory GNEsportGroupStatsSummary.fromMap(
    Map<String, dynamic> map,
    String groupId,
  ) {
    final raw = map[fieldPlayerStats] as List<dynamic>? ?? const [];
    final players = raw
        .whereType<Map<dynamic, dynamic>>()
        .map((e) =>
            GNEsportGroupPlayerEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final updatedAtRaw = map[fieldUpdatedAt];
    return GNEsportGroupStatsSummary(
      groupId: groupId,
      totalLeagues: (map[fieldTotalLeagues] as num?)?.toInt() ?? 0,
      finishedLeagues: (map[fieldFinishedLeagues] as num?)?.toInt() ?? 0,
      playerStats: players,
      updatedAt: updatedAtRaw is Timestamp ? updatedAtRaw.toDate() : null,
      schemaVersion: (map[fieldSchemaVersion] as num?)?.toInt() ?? 0,
    );
  }

  factory GNEsportGroupStatsSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    // The summary doc lives at `esports_groups/{groupId}/stats/summary`,
    // so the parent collection's parent doc is the group itself.
    final groupId = doc.reference.parent.parent?.id ?? '';
    return GNEsportGroupStatsSummary.fromMap(data, groupId);
  }

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        fieldTotalLeagues: totalLeagues,
        fieldFinishedLeagues: finishedLeagues,
        fieldPlayerStats: playerStats.map((p) => p.toJson()).toList(),
        fieldSchemaVersion: schemaVersion,
        fieldUpdatedAt: updatedAt?.millisecondsSinceEpoch,
      };

  factory GNEsportGroupStatsSummary.fromJson(Map<String, dynamic> map) {
    final raw = map[fieldPlayerStats] as List<dynamic>? ?? const [];
    final ts = map[fieldUpdatedAt] as int?;
    return GNEsportGroupStatsSummary(
      groupId: map['groupId'] as String? ?? '',
      totalLeagues: (map[fieldTotalLeagues] as num?)?.toInt() ?? 0,
      finishedLeagues: (map[fieldFinishedLeagues] as num?)?.toInt() ?? 0,
      playerStats: raw
          .whereType<Map>()
          .map((e) => GNEsportGroupPlayerEntry.fromMap(
              Map<String, dynamic>.from(e)))
          .toList(),
      updatedAt: ts == null ? null : DateTime.fromMillisecondsSinceEpoch(ts),
      schemaVersion: (map[fieldSchemaVersion] as num?)?.toInt() ??
          kCurrentSchemaVersion,
    );
  }

  @override
  List<Object?> get props => [
        groupId,
        totalLeagues,
        finishedLeagues,
        playerStats,
        updatedAt,
        schemaVersion,
      ];
}

class GNEsportGroupPlayerEntry extends Equatable {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int matches;
  final int wins;
  final int draws;
  final int losses;
  final int goals;
  final int goalsConceded;
  final int championships;
  final int runnerUps;
  final int finishedLeaguesJoined;

  const GNEsportGroupPlayerEntry({
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.matches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goals,
    required this.goalsConceded,
    required this.championships,
    required this.runnerUps,
    required this.finishedLeaguesJoined,
  });

  factory GNEsportGroupPlayerEntry.fromMap(Map<String, dynamic> map) {
    return GNEsportGroupPlayerEntry(
      userId: map['userId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      matches: (map['matches'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      draws: (map['draws'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      goals: (map['goals'] as num?)?.toInt() ?? 0,
      goalsConceded: (map['goalsConceded'] as num?)?.toInt() ?? 0,
      championships: (map['championships'] as num?)?.toInt() ?? 0,
      runnerUps: (map['runnerUps'] as num?)?.toInt() ?? 0,
      finishedLeaguesJoined:
          (map['finishedLeaguesJoined'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'matches': matches,
        'wins': wins,
        'draws': draws,
        'losses': losses,
        'goals': goals,
        'goalsConceded': goalsConceded,
        'championships': championships,
        'runnerUps': runnerUps,
        'finishedLeaguesJoined': finishedLeaguesJoined,
      };

  @override
  List<Object?> get props => [
        userId,
        displayName,
        photoUrl,
        matches,
        wins,
        draws,
        losses,
        goals,
        goalsConceded,
        championships,
        runnerUps,
        finishedLeaguesJoined,
      ];
}
