import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/league_model.dart';

enum LeagueListStatus { error, loading, loaded }

extension LeagueListStatusX on LeagueListStatus {
  bool get isError => this == LeagueListStatus.error;
  bool get isLoading => this == LeagueListStatus.loading;
  bool get isLoaded => this == LeagueListStatus.loaded;
}

class LeagueListState extends Equatable {
  final LeagueListStatus status;
  final List<LeagueModel> leagues;

  const LeagueListState({
    this.status = LeagueListStatus.loading,
    this.leagues = const [],
  });

  LeagueListState copyWith(
      {LeagueListStatus? status, List<LeagueModel>? leagues}) {
    return LeagueListState(
      status: status ?? this.status,
      leagues: leagues ?? this.leagues,
    );
  }

  @override
  List<Object?> get props => [status, leagues];
}
