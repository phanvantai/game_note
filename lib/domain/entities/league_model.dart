import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/entities/round_model.dart';

class LeagueModel extends Equatable {
  final int? id;
  final String name;
  final List<PlayerModel> players;
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
      'id': id,
      'name': name,
      'date_time': dateTime.toString(),
    };
  }

  LeagueModel copyWith({
    int? id,
    String? name,
    List<RoundModel>? rounds,
    List<PlayerModel>? players,
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
  List<Object?> get props => [id, name, rounds, dateTime];
}
