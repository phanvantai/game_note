part of 'group_bloc.dart';

abstract class GroupEvent extends Equatable {
  const GroupEvent();

  @override
  List<Object> get props => [];
}

class GetEsportGroups extends GroupEvent {}

class CreateEsportGroup extends GroupEvent {
  final String groupName;
  final String esportId;
  final String description;
  final String location;

  const CreateEsportGroup({
    required this.groupName,
    required this.esportId,
    required this.description,
    required this.location,
  });

  @override
  List<Object> get props => [groupName, esportId, description, location];
}

class AddMemberToGroup extends GroupEvent {
  final String groupId;
  final String memberId;

  const AddMemberToGroup({
    required this.groupId,
    required this.memberId,
  });

  @override
  List<Object> get props => [groupId, memberId];
}
