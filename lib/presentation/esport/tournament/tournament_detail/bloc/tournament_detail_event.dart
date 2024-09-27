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

class CreateCustomMatch extends TournamentDetailEvent {
  final GNUser homeTeam;
  final GNUser awayTeam;

  const CreateCustomMatch({
    required this.homeTeam,
    required this.awayTeam,
  });

  @override
  List<Object> get props => [homeTeam, awayTeam];
}

class UpdateEsportMatch extends TournamentDetailEvent {
  final GNEsportMatch match;

  const UpdateEsportMatch(this.match);

  @override
  List<Object> get props => [match];
}

// delete match
class DeleteEsportMatch extends TournamentDetailEvent {
  final GNEsportMatch match;

  const DeleteEsportMatch(this.match);

  @override
  List<Object> get props => [match];
}

class GetLeagueUpdated extends TournamentDetailEvent {}

class ChangeLeagueStatus extends TournamentDetailEvent {
  final GNEsportLeagueStatus status;

  const ChangeLeagueStatus(this.status);

  @override
  List<Object> get props => [status];
}

class SubmitLeagueStatus extends TournamentDetailEvent {}

class InactiveLeague extends TournamentDetailEvent {}

class UpdateStartingMedals extends TournamentDetailEvent {
  final int medals;

  const UpdateStartingMedals(this.medals);

  @override
  List<Object> get props => [medals];
}

class UpdateUnitMedals extends TournamentDetailEvent {
  final int unitMedals;

  const UpdateUnitMedals(this.unitMedals);

  @override
  List<Object> get props => [unitMedals];
}

class UpdateMatchMedals extends TournamentDetailEvent {
  final String matchId;
  final int medals;

  const UpdateMatchMedals(this.matchId, this.medals);

  @override
  List<Object> get props => [matchId, medals];
}
