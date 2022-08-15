import 'package:equatable/equatable.dart';

enum TournamentStatus { error, loading, addPlayer, done }

extension TournamentStatusX on TournamentStatus {
  bool get isError => this == TournamentStatus.error;
  bool get isLoading => this == TournamentStatus.loading;
  bool get isAddPlayer => this == TournamentStatus.addPlayer;
  bool get isDone => this == TournamentStatus.done;
}

class TournamentState extends Equatable {
  final TournamentStatus status;
  const TournamentState({
    this.status = TournamentStatus.loading,
  });

  TournamentState copyWith({
    TournamentStatus? status,
  }) {
    return TournamentState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}
