part of 'tournament_bloc.dart';

enum TournamentStatus {
  error,
  loading,
  list,
  league,
}

extension TournamentStatusX on TournamentStatus {
  bool get isError => this == TournamentStatus.error;
  bool get isLoading => this == TournamentStatus.loading;
  bool get isList => this == TournamentStatus.list;
  bool get isLeague => this == TournamentStatus.league;
}

class TournamentState extends Equatable {
  final TournamentStatus status;
  final LeagueModel? leagueModel;
  final List<PlayerModel> players;
  final List<MatchModel> matches;
  const TournamentState({
    this.leagueModel,
    this.status = TournamentStatus.loading,
    this.players = const [],
    this.matches = const [],
  });

  TournamentState copyWith({
    TournamentStatus? status,
    List<PlayerModel>? players,
    List<MatchModel>? matches,
    LeagueModel? leagueModel,
  }) {
    return TournamentState(
      status: status ?? this.status,
      players: players ?? this.players,
      matches: matches ?? this.matches,
      leagueModel: leagueModel ?? this.leagueModel,
    );
  }

  @override
  List<Object?> get props => [status, players, matches, leagueModel];
}
