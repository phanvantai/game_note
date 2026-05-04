part of 'group_bloc.dart';

abstract class GroupEvent extends Equatable {
  const GroupEvent();

  @override
  List<Object> get props => [];
}

class GetEsportGroups extends GroupEvent {}

class CreateEsportGroup extends GroupEvent {
  final String groupName;
  final String description;

  const CreateEsportGroup({required this.groupName, required this.description});

  @override
  List<Object> get props => [groupName, description];
}

class AddMemberToGroup extends GroupEvent {
  final String groupId;
  final String memberId;

  const AddMemberToGroup({required this.groupId, required this.memberId});

  @override
  List<Object> get props => [groupId, memberId];
}
