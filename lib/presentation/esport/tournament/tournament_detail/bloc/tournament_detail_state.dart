part of 'tournament_detail_bloc.dart';

class TournamentDetailState extends Equatable {
  final ViewStatus viewStatus;
  final GNEsportLeague league;
  final List<GNUser> participants;
  final String errorMessage;

  const TournamentDetailState({
    this.viewStatus = ViewStatus.initial,
    required this.league,
    this.participants = const [],
    this.errorMessage = '',
  });

  TournamentDetailState copyWith({
    ViewStatus? viewStatus,
    GNEsportLeague? league,
    List<GNUser>? participants,
    String? errorMessage,
  }) {
    return TournamentDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      league: league ?? this.league,
      participants: participants ?? this.participants,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        viewStatus,
        league,
        participants,
        errorMessage,
      ];
}
