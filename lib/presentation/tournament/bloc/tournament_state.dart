import 'package:equatable/equatable.dart';

enum TournamentStatus { error, loading, addPlayer, list }

extension TournamentStatusX on TournamentStatus {
  bool get isError => this == TournamentStatus.error;
  bool get isLoading => this == TournamentStatus.loading;
  bool get isAddPlayer => this == TournamentStatus.addPlayer;
  bool get isList => this == TournamentStatus.list;
}

class TournamentState extends Equatable {
  final TournamentStatus status;
  final TournamentState? lastState;
  const TournamentState({
    this.status = TournamentStatus.loading,
    this.lastState,
  });

  TournamentState copyWith({
    TournamentStatus? status,
    TournamentState? lastState,
  }) {
    return TournamentState(
      status: status ?? this.status,
      lastState: lastState ?? this.lastState,
    );
  }

  @override
  List<Object?> get props => [status];
}
