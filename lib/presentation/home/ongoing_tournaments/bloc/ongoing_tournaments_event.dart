part of 'ongoing_tournaments_bloc.dart';

abstract class OngoingTournamentsEvent extends Equatable {
  const OngoingTournamentsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadOngoingTournaments extends OngoingTournamentsEvent {
  final List<String> groupIds;

  const LoadOngoingTournaments(this.groupIds);

  @override
  List<Object?> get props => [groupIds];
}
