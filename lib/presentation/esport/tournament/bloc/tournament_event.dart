part of 'tournament_bloc.dart';

abstract class TournamentEvent extends Equatable {
  const TournamentEvent();

  @override
  List<Object?> get props => [];
}

class GetTournaments extends TournamentEvent {}

class AddTournament extends TournamentEvent {
  final String name;
  final String groupId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String description;

  const AddTournament({
    required this.name,
    required this.groupId,
    this.startDate,
    this.endDate,
    this.description = '',
  });

  @override
  List<Object?> get props => [name, groupId, startDate, endDate, description];
}
