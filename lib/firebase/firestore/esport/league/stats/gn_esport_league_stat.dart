import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:game_note/firebase/firestore/user/gn_user.dart';

class GNEsportLeagueStat extends Equatable {
  final String id; // ID of the league stat
  final String userId; // ID of the participant (user)
  final String leagueId; // ID of the league
  final int matchesPlayed; // total matches played
  final int goals; // total goals scored
  final int goalsConceded; // total goals conceded
  final int wins; // total number of wins
  final int draws; // total number of draws
  final int losses; // total number of losses
  final GNUser? user; // user this stat belongs to

  static const String collectionName = 'leagues_stats';

  static const String fieldId = 'id';
  static const String fieldUserId = 'userId';
  static const String fieldLeagueId = 'leagueId';
  static const String fieldMatchesPlayed = 'matchesPlayed';
  static const String fieldGoals = 'goals';
  static const String fieldGoalsConceded = 'goalsConceded';
  static const String fieldWins = 'wins';
  static const String fieldDraws = 'draws';
  static const String fieldLosses = 'losses';

  const GNEsportLeagueStat({
    required this.id,
    required this.userId,
    required this.leagueId,
    required this.matchesPlayed,
    required this.goals,
    required this.goalsConceded,
    required this.wins,
    required this.draws,
    required this.losses,
    this.user,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        leagueId,
        matchesPlayed,
        goals,
        goalsConceded,
        wins,
        draws,
        losses,
        user,
      ];

  GNEsportLeagueStat copyWith({
    String? id,
    String? userId,
    String? leagueId,
    int? matchesPlayed,
    int? goals,
    int? goalsConceded,
    int? wins,
    int? draws,
    int? losses,
    GNUser? user,
  }) {
    return GNEsportLeagueStat(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      leagueId: leagueId ?? this.leagueId,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      goals: goals ?? this.goals,
      goalsConceded: goalsConceded ?? this.goalsConceded,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      fieldUserId: userId,
      fieldLeagueId: leagueId,
      fieldMatchesPlayed: matchesPlayed,
      fieldGoals: goals,
      fieldGoalsConceded: goalsConceded,
      fieldWins: wins,
      fieldDraws: draws,
      fieldLosses: losses,
    };
  }

  factory GNEsportLeagueStat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GNEsportLeagueStat(
      id: doc.id,
      userId: data[fieldUserId],
      leagueId: data[fieldLeagueId],
      matchesPlayed: data[fieldMatchesPlayed],
      goals: data[fieldGoals],
      goalsConceded: data[fieldGoalsConceded],
      wins: data[fieldWins],
      draws: data[fieldDraws],
      losses: data[fieldLosses],
    );
  }

  int get points => wins * 3 + draws;
  int get goalDifference => goals - goalsConceded;
}
