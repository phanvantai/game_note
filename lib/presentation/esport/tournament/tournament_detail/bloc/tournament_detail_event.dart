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

class GetMatches extends TournamentDetailEvent {
  final String tournamentId;

  const GetMatches(this.tournamentId);

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

class GenerateRound extends TournamentDetailEvent {
  const GenerateRound();

  @override
  List<Object> get props => [];
}

class UpdateEsportMatch extends TournamentDetailEvent {
  final GNEsportMatch match;

  const UpdateEsportMatch(this.match);

  @override
  List<Object> get props => [match];
}
