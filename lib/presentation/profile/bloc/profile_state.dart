part of 'profile_bloc.dart';

class ProfileState extends Equatable {
  final ViewStatus viewStatus;
  final User? user;
  final String error;

  const ProfileState({
    this.viewStatus = ViewStatus.initial,
    this.user,
    this.error = '',
  });

  ProfileState copyWith({
    ViewStatus? viewStatus,
    User? user,
    String? error,
  }) {
    return ProfileState(
      viewStatus: viewStatus ?? this.viewStatus,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [viewStatus, user, error];
}
