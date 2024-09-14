part of 'tournament_detail_bloc.dart';

abstract class TournamentDetailEvent extends Equatable {
  const TournamentDetailEvent();

  @override
  List<Object> get props => [];
}

class GetParticipants extends TournamentDetailEvent {
  final String tournamentId;

  const GetParticipants(this.tournamentId);

  @override
  List<Object> get props => [tournamentId];
}
