import 'package:equatable/equatable.dart';
import 'package:pes_arena/offline/data/database/database_manager.dart';
import 'package:pes_arena/offline/domain/entities/match_model.dart';

class RoundModel extends Equatable {
  final int? id;
  final int leagueId;
  final List<MatchModel> matches;

  const RoundModel({
    this.id,
    required this.leagueId,
    this.matches = const [],
  });

  RoundModel copyWith({
    int? id,
    int? leagueId,
    List<MatchModel>? matches,
  }) {
    return RoundModel(
      id: id,
      leagueId: leagueId ?? this.leagueId,
      matches: matches ?? this.matches,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DBTableColumn.roundId: id,
      DBTableColumn.leagueId: leagueId,
    };
  }

  @override
  List<Object?> get props => [id, leagueId, matches];
}
