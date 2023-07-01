import 'package:equatable/equatable.dart';
import 'package:game_note/features/offline/data/database/database_manager.dart';
import 'package:game_note/features/offline/domain/entities/player_stats_model.dart';
import 'package:game_note/features/offline/domain/entities/round_model.dart';

class LeagueModel extends Equatable {
  final int? id;
  final String name;
  final List<PlayerStatsModel> players;
  final List<RoundModel> rounds;
  final DateTime dateTime;

  const LeagueModel({
    this.players = const [],
    this.id,
    required this.name,
    this.rounds = const [],
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      DBTableColumn.leagueId: id,
      DBTableColumn.fullname: name,
      DBTableColumn.datetime: dateTime.toString(),
    };
  }

  LeagueModel copyWith({
    int? id,
    String? name,
    List<RoundModel>? rounds,
    List<PlayerStatsModel>? players,
    DateTime? dateTime,
  }) =>
      LeagueModel(
        id: id ?? this.id,
        name: name ?? this.name,
        dateTime: dateTime ?? this.dateTime,
        rounds: rounds ?? this.rounds,
        players: players ?? this.players,
      );

  @override
  List<Object?> get props => [id, name, rounds, dateTime, players];
}
