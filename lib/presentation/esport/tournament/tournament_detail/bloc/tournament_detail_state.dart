part of 'tournament_detail_bloc.dart';

class TournamentDetailState extends Equatable {
  final ViewStatus viewStatus;
  final GNEsportLeague? league;
  final List<GNEsportLeagueStat> participants;
  final List<GNEsportMatch> matches;
  final List<GNUser> users;
  final String errorMessage;

  const TournamentDetailState({
    this.viewStatus = ViewStatus.initial,
    this.league,
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

  int countMedalOfParticipants(GNEsportLeagueStat participant) {
    if (participants.length < 2) {
      return 0;
    }
    final index = participants.indexOf(participant);
    int count = 0;
    if (index > 0) {
      count = -index;
    } else {
      // get total of indexes of participants
      count = sumRange(1, participants.length - 1);
    }
    // calculate medal of matchs of this participant
    for (final match in matches) {
      count += match.medalOfUser(participant.userId);
    }
    return count;
  }

  int countValueOfParticipants(GNEsportLeagueStat participant) {
    return countMedalOfParticipants(participant) * (league?.valueMedal ?? 0);
  }

  int sumRange(int start, int end) {
    int sum = 0;
    for (int i = start; i <= end; i++) {
      sum += i;
    }
    return sum;
  }
}

extension on GNEsportMatch {
  int medalOfUser(String userId) {
    if (medals == null ||
        medals == 0 ||
        (homeTeamId != userId && awayTeamId != userId) ||
        isFinished == false ||
        homeScore == awayScore ||
        homeScore == null ||
        awayScore == null) {
      return 0;
    }
    if (userId == homeTeamId) {
      return homeScore! > awayScore! ? medals! : -medals!;
    } else {
      return awayScore! > homeScore! ? medals! : -medals!;
    }
  }
}
