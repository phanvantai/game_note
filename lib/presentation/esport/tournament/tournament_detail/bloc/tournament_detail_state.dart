part of 'tournament_detail_bloc.dart';

class TournamentDetailState extends Equatable {
  final ViewStatus viewStatus;
  final GNEsportLeague? league;
  final List<GNEsportLeagueStat> participants;
  final List<GNEsportMatch> matches;
  final List<GNUser> users;
  final String errorMessage;

  /// Bumped every time `GetParticipantsAndMatches` finishes (success OR
  /// failure). Lets pull-to-refresh detect completion even when the new
  /// data equals the old data — without it Equatable suppresses the emit
  /// and the RefreshIndicator spins forever.
  final int refreshTick;

  const TournamentDetailState({
    this.viewStatus = ViewStatus.initial,
    this.league,
    this.participants = const [],
    this.matches = const [],
    this.errorMessage = '',
    this.users = const [],
    this.refreshTick = 0,
  });

  TournamentDetailState copyWith({
    ViewStatus? viewStatus,
    GNEsportLeague? league,
    List<GNEsportLeagueStat>? participants,
    List<GNEsportMatch>? matches,
    String? errorMessage,
    List<GNUser>? users,
    int? refreshTick,
  }) {
    return TournamentDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      league: league ?? this.league,
      participants: participants ?? this.participants,
      matches: matches ?? this.matches,
      errorMessage: errorMessage ?? this.errorMessage,
      users: users ?? this.users,
      refreshTick: refreshTick ?? this.refreshTick,
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
        refreshTick,
      ];

  bool get currentUserIsMember {
    return /*participants.any((element) =>
            element.userId == FirebaseAuth.instance.currentUser?.uid) ||*/
        (league?.group?.members ?? <String>[]).any(
            (element) => element == FirebaseAuth.instance.currentUser?.uid);
  }

  bool get currentUserIsLeagueAdmin {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == league?.group?.ownerId) {
      return true;
    }
    return league?.ownerId == FirebaseAuth.instance.currentUser?.uid;
  }

  List<GNEsportMatch> get fixtures {
    return matches.where((element) => !element.isFinished).toList();
  }

  List<GNEsportMatch> get results {
    return matches.where((element) => element.isFinished).toList();
  }
}
