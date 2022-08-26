import 'package:equatable/equatable.dart';
import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/domain/entities/match_model.dart';

class RoundModel extends Equatable {
  final int? id;
  final int leagueId;
  final List<MatchModel> matches;

  const RoundModel({
    required this.id,
    required this.leagueId,
    required this.matches,
  });

  Map<String, dynamic> toMap() {
    return {
      DBTableColumn.roundId: id,
      DBTableColumn.leagueId: leagueId,
    };
  }

  @override
  List<Object?> get props => [id, matches];
}
