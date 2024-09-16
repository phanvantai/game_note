part of 'tournament_detail_bloc.dart';

class TournamentDetailState extends Equatable {
  final ViewStatus viewStatus;
  final GNEsportLeague league;
  final List<GNEsportLeagueStat> participants;
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
    List<GNEsportLeagueStat>? participants,
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

  bool get currentUserIsMember {
    return (league.group?.members ?? <String>[])
        .any((element) => element == FirebaseAuth.instance.currentUser?.uid);
  }
}
