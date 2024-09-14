import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// match model is sub collection of round
class GNEsportMatch extends Equatable {
  final String id; // match id
  final String homeTeamId; // home team id
  final String awayTeamId; // away team id
  final int homeScore; // home team score
  final int awayScore; // away team score
  final DateTime date; // match date
  final bool isFinished; // match is finished
  final String roundId; // round id
  final String leagueId; // league id

  // esport_matches is subcollection of esport_rounds
  // esports_leagues/{leagueId}/esports_rounds/{roundId}/esports_matches/{matchId}
  static const String collectionName = 'esports_matches';

  static const String fieldId = 'id';
  static const String fieldHomeTeamId = 'homeTeamId';
  static const String fieldAwayTeamId = 'awayTeamId';
  static const String fieldHomeScore = 'homeScore';
  static const String fieldAwayScore = 'awayScore';
  static const String fieldDate = 'date';
  static const String fieldIsFinished = 'isFinished';
  static const String fieldRoundId = 'roundId';
  static const String fieldLeagueId = 'leagueId';

  const GNEsportMatch({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.date,
    required this.isFinished,
    required this.roundId,
    required this.leagueId,
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
        roundId,
        leagueId,
      ];

  GNEsportMatch copyWith({
    String? id,
    String? homeTeamId,
    String? awayTeamId,
    int? homeScore,
    int? awayScore,
    DateTime? date,
    bool? isFinished,
    String? roundId,
    String? leagueId,
  }) {
    return GNEsportMatch(
      id: id ?? this.id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      date: date ?? this.date,
      isFinished: isFinished ?? this.isFinished,
      roundId: roundId ?? this.roundId,
      leagueId: leagueId ?? this.leagueId,
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
      fieldRoundId: roundId,
      fieldLeagueId: leagueId,
    };
  }

  factory GNEsportMatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GNEsportMatch(
      id: doc.id,
      homeTeamId: data[fieldHomeTeamId],
      awayTeamId: data[fieldAwayTeamId],
      homeScore: data[fieldHomeScore],
      awayScore: data[fieldAwayScore],
      date: (data[fieldDate] as Timestamp).toDate(),
      isFinished: data[fieldIsFinished],
      roundId: data[fieldRoundId],
      leagueId: data[fieldLeagueId],
    );
  }
}
