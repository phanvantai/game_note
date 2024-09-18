part of 'tournament_detail_bloc.dart';

class TournamentDetailState extends Equatable {
  final ViewStatus viewStatus;
  final GNEsportLeague league;
  final List<GNEsportLeagueStat> participants;
  final List<GNEsportMatch> matches;
  final List<GNUser> users;
  final String errorMessage;

  const TournamentDetailState({
    this.viewStatus = ViewStatus.initial,
    required this.league,
    this.participants = const [],
    this.matches = const [],
    this.errorMessage = '',
    this.users = const [],
  });

  TournamentDetailState copyWith({
    ViewStatus? viewStatus,
    GNEsportLeague? league,
    List<GNEsportLeagueStat>? participants,
    List<GNEsportMatch>? matches,
    String? errorMessage,
    List<GNUser>? users,
  }) {
    return TournamentDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      league: league ?? this.league,
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      errorMessage: errorMessage ?? this.errorMessage,
      users: users ?? this.users,
    );
  }

  @override
  List<Object?> get props => [
        viewStatus,
        league,
        participants,
        matches,
        errorMessage,
        users,
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
