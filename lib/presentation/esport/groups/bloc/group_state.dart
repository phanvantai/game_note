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

  @override
  List<Object?> get props => [viewStatus, groups, errorMessage];
}
