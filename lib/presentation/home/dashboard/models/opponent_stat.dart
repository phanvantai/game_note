import 'package:equatable/equatable.dart';

class OpponentStat extends Equatable {
  final String opponentId;
  final String opponentDisplayName;
  final String? opponentPhotoUrl;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;

  const OpponentStat({
    required this.opponentId,
    required this.opponentDisplayName,
    this.opponentPhotoUrl,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  double rate(int n) => matchesPlayed == 0 ? 0 : n / matchesPlayed;

  @override
  List<Object?> get props => [
    opponentId,
    opponentDisplayName,
    opponentPhotoUrl,
    matchesPlayed,
    wins,
    draws,
    losses,
  ];
}
