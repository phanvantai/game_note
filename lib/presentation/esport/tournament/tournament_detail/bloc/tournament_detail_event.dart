part of 'tournament_detail_bloc.dart';

abstract class TournamentDetailEvent extends Equatable {
  const TournamentDetailEvent();

  @override
  List<Object> get props => [];
}

class GetParticipantStats extends TournamentDetailEvent {
  final String tournamentId;

  const GetParticipantStats(this.tournamentId);

  @override
  List<Object> get props => [tournamentId];
}

class AddParticipant extends TournamentDetailEvent {
  final String tournamentId;
  final String userId;

  const AddParticipant(this.tournamentId, this.userId);

  @override
  List<Object> get props => [tournamentId, userId];
}
