part of 'tournament_detail_bloc.dart';

class TournamentDetailState extends Equatable {
  final ViewStatus viewStatus;
  final GNEsportLeague league;
  final List<GNEsportLeagueStat> participants;
  final List<GNEsportMatch> matches;
  final String errorMessage;

  const TournamentDetailState({
    this.viewStatus = ViewStatus.initial,
    required this.league,
    this.participants = const [],
    this.matches = const [],
    this.errorMessage = '',
  });

  TournamentDetailState copyWith({
    ViewStatus? viewStatus,
    GNEsportLeague? league,
    List<GNEsportLeagueStat>? participants,
    List<GNEsportMatch>? matches,
    String? errorMessage,
  }) {
    return TournamentDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      league: league ?? this.league,
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        viewStatus,
        league,
        participants,
        matches,
        errorMessage,
      ];

  bool get currentUserIsMember {
    return (league.group?.members ?? <String>[])
        .any((element) => element == FirebaseAuth.instance.currentUser?.uid);
  }

  List<GNEsportMatch> get fixtures {
    return matches.where((element) => !element.isFinished).toList();
  }

  List<GNEsportMatch> get results {
    return matches.where((element) => element.isFinished).toList();
  }
}
