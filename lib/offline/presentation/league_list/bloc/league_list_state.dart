part of 'league_list_bloc.dart';

enum LeagueListStatus { error, loading, loaded }

extension LeagueListStatusX on LeagueListStatus {
  bool get isError => this == LeagueListStatus.error;
  bool get isLoading => this == LeagueListStatus.loading;
  bool get isLoaded => this == LeagueListStatus.loaded;
}

class LeagueListState extends Equatable {
  final LeagueListStatus status;
  final List<LeagueModel> leagues;
  final LeagueModel? newLeague;

  const LeagueListState({
    this.status = LeagueListStatus.loading,
    this.leagues = const [],
    this.newLeague,
  });

  LeagueListState copyWith(
      {LeagueListStatus? status,
      List<LeagueModel>? leagues,
      LeagueModel? newLeague}) {
    return LeagueListState(
      status: status ?? this.status,
      leagues: leagues ?? this.leagues,
      newLeague: newLeague,
    );
  }

  @override
  List<Object?> get props => [status, leagues, newLeague];
}
