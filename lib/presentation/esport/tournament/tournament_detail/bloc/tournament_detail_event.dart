part of 'tournament_detail_bloc.dart';

abstract class TournamentDetailEvent extends Equatable {
  const TournamentDetailEvent();

  @override
  List<Object?> get props => [];
}

class OpenLeagueDetail extends TournamentDetailEvent {
  final String leagueId;

  const OpenLeagueDetail(this.leagueId);

  @override
  List<Object?> get props => [leagueId];
}

/// Compatibility event for callers that have not yet migrated to
/// [OpenLeagueDetail].
@Deprecated('Use OpenLeagueDetail instead.')
class GetLeague extends OpenLeagueDetail {
  const GetLeague(super.leagueId);
}

class EnsureDetailSubscriptions extends TournamentDetailEvent {
  final String leagueId;

  const EnsureDetailSubscriptions(this.leagueId);

  @override
  List<Object?> get props => [leagueId];
}

class RetryDetailSlice extends TournamentDetailEvent {
  final TournamentDetailSlice slice;

  const RetryDetailSlice(this.slice);

  @override
  List<Object?> get props => [slice];
}

class LeagueSnapshotReceived extends TournamentDetailEvent {
  final GNEsportLeague? league;

  const LeagueSnapshotReceived(this.league);

  @override
  List<Object?> get props => [league];
}

class StatsSnapshotReceived extends TournamentDetailEvent {
  final List<GNEsportLeagueStat> stats;

  const StatsSnapshotReceived(this.stats);

  @override
  List<Object?> get props => [stats];
}

class MatchesSnapshotReceived extends TournamentDetailEvent {
  final List<GNEsportMatch> matches;

  const MatchesSnapshotReceived(this.matches);

  @override
  List<Object?> get props => [matches];
}

class DetailStreamFailed extends TournamentDetailEvent {
  final TournamentDetailSlice slice;
  final Object error;

  const DetailStreamFailed(this.slice, this.error);

  @override
  List<Object?> get props => [slice, error];
}

class AddParticipant extends TournamentDetailEvent {
  final String tournamentId;
  final String userId;

  const AddParticipant(this.tournamentId, this.userId);

  @override
  List<Object> get props => [tournamentId, userId];
}

class AddMultipleParticipants extends TournamentDetailEvent {
  final String tournamentId;
  final List<String> userIds;

  const AddMultipleParticipants(this.tournamentId, this.userIds);

  @override
  List<Object> get props => [tournamentId, userIds];
}

class GenerateRound extends TournamentDetailEvent {
  const GenerateRound();

  @override
  List<Object> get props => [];
}

class GenerateGroupRound extends TournamentDetailEvent {
  final String groupId;

  const GenerateGroupRound(this.groupId);

  @override
  List<Object> get props => [groupId];
}

class CreateCustomMatch extends TournamentDetailEvent {
  final GNUser homeTeam;
  final GNUser awayTeam;

  const CreateCustomMatch({required this.homeTeam, required this.awayTeam});

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

class ChangeLeagueStatus extends TournamentDetailEvent {
  final GNEsportLeagueStatus status;

  const ChangeLeagueStatus(this.status);

  @override
  List<Object> get props => [status];
}

class SubmitLeagueStatus extends TournamentDetailEvent {}

class InactiveLeague extends TournamentDetailEvent {}

class LeagueDeleted extends TournamentDetailEvent {}

class UpdateLeagueCostConfig extends TournamentDetailEvent {
  final bool rankPayoutEnabled;
  final List<int> rankPayouts;
  final int defaultMatchCost;
  final bool defaultPerGoalEnabled;
  final int defaultCostPerGoal;

  const UpdateLeagueCostConfig({
    required this.rankPayoutEnabled,
    required this.rankPayouts,
    required this.defaultMatchCost,
    required this.defaultPerGoalEnabled,
    required this.defaultCostPerGoal,
  });

  @override
  List<Object> get props => [
    rankPayoutEnabled,
    rankPayouts,
    defaultMatchCost,
    defaultPerGoalEnabled,
    defaultCostPerGoal,
  ];
}

/// Admin-only: rebuild stats for the current league from its finished
/// matches.
class RecomputeStats extends TournamentDetailEvent {}

class GenerateCup extends TournamentDetailEvent {
  final List<String> seededTeamIds;

  const GenerateCup(this.seededTeamIds);

  @override
  List<Object> get props => [seededTeamIds];
}

class GenerateFull extends TournamentDetailEvent {
  final List<List<String>> groups;
  final int advanceCount;

  const GenerateFull({required this.groups, required this.advanceCount});

  @override
  List<Object> get props => [groups, advanceCount];
}

class SelectGroup extends TournamentDetailEvent {
  final String? groupId;

  const SelectGroup(this.groupId);

  @override
  List<Object> get props => [groupId ?? ''];
}
