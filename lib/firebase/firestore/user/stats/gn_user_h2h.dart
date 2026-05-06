import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'gn_user_stats_summary.dart';

/// Head-to-head aggregate from `uid`'s perspective vs a specific opponent.
/// Stored at `users/{uid}/h2h/{opponentUid}`. Symmetric: every finished
/// match writes both `users/A/h2h/B` and `users/B/h2h/A` (B's view is the
/// inverse of A's).
class GNUserH2H extends Equatable {
  final String userId;
  final String opponentId;
  final String opponentDisplayName;

  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goals;
  final int goalsConceded;

  final DateTime? lastMetAt;
  final DateTime? updatedAt;

  static const String subCollectionName = 'h2h';

  static const String fieldOpponentId = 'opponentId';
  static const String fieldOpponentDisplayName = 'opponentDisplayName';
  static const String fieldMatchesPlayed = 'matchesPlayed';
  static const String fieldWins = 'wins';
  static const String fieldDraws = 'draws';
  static const String fieldLosses = 'losses';
  static const String fieldGoals = 'goals';
  static const String fieldGoalsConceded = 'goalsConceded';
  static const String fieldLastMetAt = 'lastMetAt';
  static const String fieldUpdatedAt = 'updatedAt';

  const GNUserH2H({
    required this.userId,
    required this.opponentId,
    required this.opponentDisplayName,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goals,
    required this.goalsConceded,
    required this.lastMetAt,
    required this.updatedAt,
  });

  factory GNUserH2H.empty({
    required String userId,
    required String opponentId,
    String opponentDisplayName = '',
  }) {
    return GNUserH2H(
      userId: userId,
      opponentId: opponentId,
      opponentDisplayName: opponentDisplayName,
      matchesPlayed: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      goals: 0,
      goalsConceded: 0,
      lastMetAt: null,
      updatedAt: null,
    );
  }

  factory GNUserH2H.fromMap(
    Map<String, dynamic> map, {
    required String userId,
    required String opponentId,
  }) {
    return GNUserH2H(
      userId: userId,
      opponentId: opponentId,
      opponentDisplayName:
          map[fieldOpponentDisplayName] as String? ?? '',
      matchesPlayed: (map[fieldMatchesPlayed] as num?)?.toInt() ?? 0,
      wins: (map[fieldWins] as num?)?.toInt() ?? 0,
      draws: (map[fieldDraws] as num?)?.toInt() ?? 0,
      losses: (map[fieldLosses] as num?)?.toInt() ?? 0,
      goals: (map[fieldGoals] as num?)?.toInt() ?? 0,
      goalsConceded: (map[fieldGoalsConceded] as num?)?.toInt() ?? 0,
      lastMetAt: tsToDate(map[fieldLastMetAt]),
      updatedAt: tsToDate(map[fieldUpdatedAt]),
    );
  }

  // coverage:ignore-start
  factory GNUserH2H.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final userId = doc.reference.parent.parent?.id ?? '';
    return GNUserH2H.fromMap(data, userId: userId, opponentId: doc.id);
  }
  // coverage:ignore-end

  Map<String, dynamic> toMap() {
    return {
      fieldOpponentId: opponentId,
      fieldOpponentDisplayName: opponentDisplayName,
      fieldMatchesPlayed: matchesPlayed,
      fieldWins: wins,
      fieldDraws: draws,
      fieldLosses: losses,
      fieldGoals: goals,
      fieldGoalsConceded: goalsConceded,
      fieldLastMetAt:
          lastMetAt == null ? null : Timestamp.fromDate(lastMetAt!),
      fieldUpdatedAt:
          updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  double? get winRate => matchesPlayed == 0 ? null : wins / matchesPlayed;
  int get goalDifference => goals - goalsConceded;

  @override
  List<Object?> get props => [
    userId,
    opponentId,
    opponentDisplayName,
    matchesPlayed,
    wins,
    draws,
    losses,
    goals,
    goalsConceded,
    lastMetAt,
    updatedAt,
  ];
}
