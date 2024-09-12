part of 'user_bloc.dart';

class UserState extends Equatable {
  final ViewStatus viewStatus;
  final List<GNUser> users;

  const UserState({
    this.viewStatus = ViewStatus.initial,
    this.users = const [],
  });

  UserState copyWith({
    ViewStatus? viewStatus,
    List<GNUser>? users,
  }) {
    return UserState(
      viewStatus: viewStatus ?? this.viewStatus,
      users: users ?? this.users,
    );
  }

  @override
  List<Object?> get props => [viewStatus, users];
}
