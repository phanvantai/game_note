part of 'group_detail_bloc.dart';

class GroupDetailState extends Equatable {
  final ViewStatus viewStatus;
  final List<GNUser> members;
  final GNEsportGroup group;
  final String errorMessage;

  const GroupDetailState({
    this.viewStatus = ViewStatus.initial,
    this.members = const [],
    required this.group,
    this.errorMessage = '',
  });

  GroupDetailState copyWith({
    ViewStatus? viewStatus,
    List<GNUser>? members,
    GNEsportGroup? group,
    String? errorMessage,
  }) {
    return GroupDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      members: members ?? this.members,
      group: group ?? this.group,
      errorMessage: errorMessage ?? '',
    );
  }

  bool get isOwner {
    return group.ownerId == FirebaseAuth.instance.currentUser?.uid;
  }

  bool get currentUserIsMember {
    return members
        .any((element) => element.id == FirebaseAuth.instance.currentUser?.uid);
  }

  String? get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  List<Object?> get props => [viewStatus, members, group, errorMessage];
}
