import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/entities/round_model.dart';

enum LeagueStatus { error, loading, empty, addingPlayer, loaded, updating }

extension LeagueStatusX on LeagueStatus {
  bool get isError => this == LeagueStatus.error;
  bool get isLoading => this == LeagueStatus.loading;
  bool get isEmpty => this == LeagueStatus.empty;
  bool get isAddingPlayer => this == LeagueStatus.addingPlayer;
  bool get isLoaded => this == LeagueStatus.loaded;
  bool get isUpdating => this == LeagueStatus.updating;
}

class LeagueState extends Equatable {
  final LeagueStatus status;
  final List<PlayerModel> players;
  final List<RoundModel> rounds;

  const LeagueState({
    required this.status,
    this.players = const [],
    this.rounds = const [],
  });

  LeagueState copyWith({
    LeagueStatus? status,
    List<PlayerModel>? players,
    List<RoundModel>? rounds,
  }) {
    return LeagueState(
      status: status ?? this.status,
      players: players ?? this.players,
      rounds: rounds ?? this.rounds,
    );
  }

  @override
  List<Object?> get props => [status, players, rounds];
}
