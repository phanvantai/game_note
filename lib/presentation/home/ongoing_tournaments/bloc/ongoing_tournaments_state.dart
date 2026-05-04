part of 'ongoing_tournaments_bloc.dart';

class OngoingTournamentsState extends Equatable {
  final ViewStatus status;
  final List<GNEsportLeague> leagues;
  final List<String> loadedGroupIds;
  final String errorMessage;

  const OngoingTournamentsState({
    this.status = ViewStatus.initial,
    this.leagues = const [],
    this.loadedGroupIds = const [],
    this.errorMessage = '',
  });

  OngoingTournamentsState copyWith({
    ViewStatus? status,
    List<GNEsportLeague>? leagues,
    List<String>? loadedGroupIds,
    String? errorMessage,
  }) {
    return OngoingTournamentsState(
      status: status ?? this.status,
      leagues: leagues ?? this.leagues,
      loadedGroupIds: loadedGroupIds ?? this.loadedGroupIds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, leagues, loadedGroupIds, errorMessage];
}
