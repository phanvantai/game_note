part of 'group_detail_bloc.dart';

abstract class GroupDetailEvent extends Equatable {
  const GroupDetailEvent();

  @override
  List<Object?> get props => [];
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
