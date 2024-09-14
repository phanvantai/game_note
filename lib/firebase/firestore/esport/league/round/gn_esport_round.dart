import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GNEsportRound extends Equatable {
  final String id; // round id
  final String leagueId; // id of the league this round belongs to
  final String name; // round name (e.g., "Quarterfinals", "Round 1")
  final int roundNumber; // round number (e.g., 1, 2, 3)
  final DateTime date; // round date
  final bool isFinished; // whether the round is finished

  // esport_rounds is subcollection of esport_leagues
  // esports_leagues/{leagueId}/esports_rounds/{roundId}
  static const String collectionName = 'esports_rounds';

  static const String fieldId = 'id';
  static const String fieldLeagueId = 'leagueId';
  static const String fieldName = 'name';
  static const String fieldRoundNumber = 'roundNumber';
  static const String fieldDate = 'date';
  static const String fieldIsFinished = 'isFinished';

  const GNEsportRound({
    required this.id,
    required this.leagueId,
    required this.name,
    required this.roundNumber,
    required this.date,
    required this.isFinished,
  });

  @override
  List<Object?> get props => [
        id,
        leagueId,
        name,
        roundNumber,
        date,
        isFinished,
      ];

  GNEsportRound copyWith({
    String? id,
    String? leagueId,
    String? name,
    int? roundNumber,
    DateTime? date,
    bool? isFinished,
  }) {
    return GNEsportRound(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      name: name ?? this.name,
      roundNumber: roundNumber ?? this.roundNumber,
      date: date ?? this.date,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      fieldLeagueId: leagueId,
      fieldName: name,
      fieldRoundNumber: roundNumber,
      fieldDate: Timestamp.fromDate(date),
      fieldIsFinished: isFinished,
    };
  }

  factory GNEsportRound.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GNEsportRound(
      id: doc.id,
      leagueId: data[fieldLeagueId],
      name: data[fieldName],
      roundNumber: data[fieldRoundNumber],
      date: (data[fieldDate] as Timestamp).toDate(),
      isFinished: data[fieldIsFinished],
    );
  }
}
