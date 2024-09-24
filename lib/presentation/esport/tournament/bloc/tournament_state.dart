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

  List<GNEsportLeague> get userLeagues => leagues.where((league) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (league.ownerId == user.uid) {
            return true;
          }
          return league.participants.contains(user.uid);
        } else {
          return false;
        }
      }).toList();

  List<GNEsportLeague> get otherLeagues => leagues.where((league) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          return !league.participants.contains(user.uid);
        } else {
          return false;
        }
      }).toList();
}
