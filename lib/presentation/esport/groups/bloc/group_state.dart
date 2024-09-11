part of 'group_bloc.dart';

class GroupState extends Equatable {
  final ViewStatus viewStatus;
  final List<GNEsportGroup> groups;
  final String errorMessage;

  const GroupState({
    this.viewStatus = ViewStatus.initial,
    this.groups = const [],
    this.errorMessage = '',
  });

  GroupState copyWith({
    ViewStatus? viewStatus,
    List<GNEsportGroup>? groups,
    String? errorMessage,
  }) {
    return GroupState(
      viewStatus: viewStatus ?? this.viewStatus,
      groups: groups ?? this.groups,
      errorMessage: errorMessage ?? '',
    );
  }

  List<GNEsportGroup> get userGroups => groups.where((group) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          return group.members.contains(user.uid);
        } else {
          return false;
        }
      }).toList();

  List<GNEsportGroup> get otherGroups => groups.where((group) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          return !group.members.contains(user.uid);
        } else {
          return false;
        }
      }).toList();

  @override
  List<Object?> get props => [viewStatus, groups, errorMessage];
}
