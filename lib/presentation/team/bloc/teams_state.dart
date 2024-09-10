part of 'teams_bloc.dart';

class TeamsState extends Equatable {
  final ViewStatus viewStatus;
  final List<GNTeam> myTeams;
  final List<GNTeam> otherTeams;
  final String errorMessage;

  const TeamsState({
    this.viewStatus = ViewStatus.initial,
    this.myTeams = const [],
    this.otherTeams = const [],
    this.errorMessage = '',
  });

  TeamsState copyWith({
    ViewStatus? viewStatus,
    List<GNTeam>? myTeams,
    List<GNTeam>? otherTeams,
    String? errorMessage,
  }) {
    return TeamsState(
      viewStatus: viewStatus ?? this.viewStatus,
      myTeams: myTeams ?? this.myTeams,
      otherTeams: otherTeams ?? this.otherTeams,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [viewStatus, myTeams, otherTeams, errorMessage];
}
