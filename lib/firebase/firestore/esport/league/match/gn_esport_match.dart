import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../user/gn_user.dart';

// match model is sub collection of round
class GNEsportMatch extends Equatable {
  final String id; // match id
  final String homeTeamId; // home team id
  final String awayTeamId; // away team id
  final int? homeScore; // home team score
  final int? awayScore; // away team score
  final DateTime date; // match date
  final bool isFinished; // match is finished
  final String leagueId; // league id
  // Override tiền cho riêng trận này (VND). null ⇒ dùng league.defaultMatchCost.
  // 0 ⇒ trận này không tính tiền.
  final int? matchCost;

  /// Server-assigned timestamp of the last write. Used as an optimistic-lock
  /// version for concurrent score updates: the UI captures this when the
  /// edit dialog opens and the transaction rejects the write if it doesn't
  /// match anymore. Null on legacy docs that pre-date this field.
  final Timestamp? updatedAt;

  // 'group' | 'knockout' | null (league mode)
  final String? phase;
  // full mode group stage: 'A', 'B', 'C'...
  final String? groupId;
  // 0-based round index in knockout (0 = first round, last = final)
  final int? knockoutRound;
  // 0-based slot position within a knockout round
  final int? knockoutSlot;
  // ID of the match the winner advances to. Null for the final.
  final String? nextMatchId;

  final GNUser? homeTeam;
  final GNUser? awayTeam;

  // esport_matches is subcollection of esports_leagues
  // esports_leagues/{leagueId}/leagues_matches/{matchId}
  static const String collectionName = 'leagues_matches';

  static const String fieldId = 'id';
  static const String fieldHomeTeamId = 'homeTeamId';
  static const String fieldAwayTeamId = 'awayTeamId';
  static const String fieldHomeScore = 'homeScore';
  static const String fieldAwayScore = 'awayScore';
  static const String fieldDate = 'date';
  static const String fieldIsFinished = 'isFinished';
  static const String fieldLeagueId = 'leagueId';
  static const String fieldMatchCost = 'matchCost';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldPhase = 'phase';
  static const String fieldGroupId = 'groupId';
  static const String fieldKnockoutRound = 'knockoutRound';
  static const String fieldKnockoutSlot = 'knockoutSlot';
  static const String fieldNextMatchId = 'nextMatchId';

  const GNEsportMatch({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore,
    this.awayScore,
    required this.date,
    required this.isFinished,
    required this.leagueId,
    this.homeTeam,
    this.awayTeam,
    this.matchCost,
    this.updatedAt,
    this.phase,
    this.groupId,
    this.knockoutRound,
    this.knockoutSlot,
    this.nextMatchId,
  });

  @override
  List<Object?> get props => [
        id,
        homeTeamId,
        awayTeamId,
        homeScore,
        awayScore,
        date,
        isFinished,
        leagueId,
        matchCost,
        updatedAt,
        phase,
        groupId,
        knockoutRound,
        knockoutSlot,
        nextMatchId,
      ];

  GNEsportMatch copyWith({
    String? id,
    String? homeTeamId,
    String? awayTeamId,
    int? homeScore,
    int? awayScore,
    DateTime? date,
    bool? isFinished,
    String? leagueId,
    GNUser? homeTeam,
    GNUser? awayTeam,
    int? matchCost,
    Timestamp? updatedAt,
    String? phase,
    String? groupId,
    int? knockoutRound,
    int? knockoutSlot,
    String? nextMatchId,
  }) {
    return GNEsportMatch(
      id: id ?? this.id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      date: date ?? this.date,
      isFinished: isFinished ?? this.isFinished,
      leagueId: leagueId ?? this.leagueId,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      matchCost: matchCost ?? this.matchCost,
      updatedAt: updatedAt ?? this.updatedAt,
      phase: phase ?? this.phase,
      groupId: groupId ?? this.groupId,
      knockoutRound: knockoutRound ?? this.knockoutRound,
      knockoutSlot: knockoutSlot ?? this.knockoutSlot,
      nextMatchId: nextMatchId ?? this.nextMatchId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      fieldHomeTeamId: homeTeamId,
      fieldAwayTeamId: awayTeamId,
      fieldHomeScore: homeScore,
      fieldAwayScore: awayScore,
      fieldDate: Timestamp.fromDate(date),
      fieldIsFinished: isFinished,
      fieldLeagueId: leagueId,
      fieldMatchCost: matchCost,
      if (phase != null) fieldPhase: phase,
      if (groupId != null) fieldGroupId: groupId,
      if (knockoutRound != null) fieldKnockoutRound: knockoutRound,
      if (knockoutSlot != null) fieldKnockoutSlot: knockoutSlot,
      if (nextMatchId != null) fieldNextMatchId: nextMatchId,
    };
  }

  factory GNEsportMatch.fromFirestore(DocumentSnapshot doc) {
    return GNEsportMatch.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Pure factory cho test — không cần `DocumentSnapshot`.
  factory GNEsportMatch.fromMap(Map<String, dynamic> data, String id) {
    DateTime toDate(Object? v) {
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    return GNEsportMatch(
      id: id,
      homeTeamId: data[fieldHomeTeamId],
      awayTeamId: data[fieldAwayTeamId],
      homeScore: data[fieldHomeScore] ?? 0,
      awayScore: data[fieldAwayScore] ?? 0,
      date: toDate(data[fieldDate]),
      isFinished: data[fieldIsFinished],
      leagueId: data[fieldLeagueId],
      matchCost: (data[fieldMatchCost] as num?)?.toInt(),
      updatedAt: data[fieldUpdatedAt] is Timestamp
          ? data[fieldUpdatedAt] as Timestamp
          : null,
      phase: data[fieldPhase] as String?,
      groupId: data[fieldGroupId] as String?,
      knockoutRound: (data[fieldKnockoutRound] as num?)?.toInt(),
      knockoutSlot: (data[fieldKnockoutSlot] as num?)?.toInt(),
      nextMatchId: data[fieldNextMatchId] as String?,
    );
  }
}
