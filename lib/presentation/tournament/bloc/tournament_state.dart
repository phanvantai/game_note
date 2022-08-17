import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';

enum TournamentStatus {
  error,
  loading,
  addPlayer,
  list,
  tournament,
  updatingTournament
}

extension TournamentStatusX on TournamentStatus {
  bool get isError => this == TournamentStatus.error;
  bool get isLoading => this == TournamentStatus.loading;
  bool get isAddPlayer => this == TournamentStatus.addPlayer;
  bool get isList => this == TournamentStatus.list;
  bool get isTournament => this == TournamentStatus.tournament;
  bool get isUpdatingTournament => this == TournamentStatus.updatingTournament;
}

class TournamentState extends Equatable {
  final TournamentStatus status;
  final TournamentState? lastState;
  final List<PlayerModel> players;
  final List<MatchModel> matches;
  const TournamentState({
    this.status = TournamentStatus.loading,
    this.lastState,
    this.players = const [],
    this.matches = const [],
  });

  TournamentState copyWith({
    TournamentStatus? status,
    TournamentState? lastState,
    List<PlayerModel>? players,
    List<MatchModel>? matches,
  }) {
    return TournamentState(
      status: status ?? this.status,
      lastState: lastState ?? this.lastState,
      players: players ?? this.players,
      matches: matches ?? this.matches,
    );
  }

  @override
  List<Object?> get props => [status, lastState, players, matches];
}
