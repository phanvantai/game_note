part of 'tournament_bloc.dart';

class TournamentState extends Equatable {
  final ViewStatus viewStatus;
  final List<GNEsportLeague> leagues;
  final String errorMessage;

  const TournamentState({
    this.viewStatus = ViewStatus.initial,
    this.leagues = const [],
    this.errorMessage = '',
  });

  TournamentState copyWith({
    ViewStatus? viewStatus,
    List<GNEsportLeague>? leagues,
    String? errorMessage,
  }) {
    return TournamentState(
      viewStatus: viewStatus ?? this.viewStatus,
      leagues: leagues ?? this.leagues,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [viewStatus, leagues, errorMessage];
}
