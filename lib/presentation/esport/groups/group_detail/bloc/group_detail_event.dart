part of 'group_detail_bloc.dart';

abstract class GroupDetailEvent extends Equatable {
  const GroupDetailEvent();

  @override
  List<Object?> get props => [];
}

class GetGroupDetail extends GroupDetailEvent {
  final String groupId;

  const GetGroupDetail(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class GetMembers extends GroupDetailEvent {
  final String groupId;

  const GetMembers(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class AddMember extends GroupDetailEvent {
  final String groupId;
  final String userId;

  const AddMember(this.groupId, this.userId);

  @override
  List<Object?> get props => [groupId, userId];
}

class RemoveMember extends GroupDetailEvent {
  final String groupId;
  final String userId;

  const RemoveMember(this.groupId, this.userId);

  @override
  List<Object?> get props => [groupId, userId];
}

class LoadGroupLeagues extends GroupDetailEvent {
  final String groupId;

  const LoadGroupLeagues(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

class ReplaceLeagueParticipant extends GroupDetailEvent {
  final String leagueId;
  final String oldUserId;
  final String newUserId;

  const ReplaceLeagueParticipant({
    required this.leagueId,
    required this.oldUserId,
    required this.newUserId,
  });

  @override
  List<Object?> get props => [leagueId, oldUserId, newUserId];
}

class LoadGroupOverview extends GroupDetailEvent {
  final String groupId;
  final bool forceRefresh;

  const LoadGroupOverview(this.groupId, {this.forceRefresh = false});

  @override
  List<Object?> get props => [groupId, forceRefresh];
}

class AddPlaceholderMember extends GroupDetailEvent {
  final String groupId;
  final String displayName;

  const AddPlaceholderMember(this.groupId, this.displayName);

  @override
  List<Object?> get props => [groupId, displayName];
}

class SetLeagueMergeCompleted extends GroupDetailEvent {
  final String leagueId;
  final bool completed;

  const SetLeagueMergeCompleted({
    required this.leagueId,
    required this.completed,
  });

  @override
  List<Object?> get props => [leagueId, completed];
}

/// Lọc group overview theo năm. [year] == null → hiện all-time.
class FilterGroupOverviewByYear extends GroupDetailEvent {
  final int? year;

  const FilterGroupOverviewByYear(this.year);

  @override
  List<Object?> get props => [year];
}
