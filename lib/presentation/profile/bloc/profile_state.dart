part of 'profile_bloc.dart';

class ProfileState extends Equatable {
  final ViewStatus viewStatus;
  final UserModel? user;
  final String error;

  const ProfileState({
    this.viewStatus = ViewStatus.initial,
    this.user,
    this.error = '',
  });

  ProfileState copyWith({
    ViewStatus? viewStatus,
    UserModel? user,
    String? error,
  }) {
    return ProfileState(
      viewStatus: viewStatus ?? this.viewStatus,
      user: user ?? this.user,
      error: error ?? '',
    );
  }

  String get displayUser =>
      user?.displayName ?? user?.phoneNumber ?? user?.email ?? 'Chưa đặt tên';

  @override
  List<Object?> get props => [viewStatus, user, error];
}
