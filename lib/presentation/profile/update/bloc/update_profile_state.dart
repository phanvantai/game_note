part of 'update_profile_bloc.dart';

class UpdateProfileState extends Equatable {
  final ViewStatus viewStatus;
  final GNUser? user;
  final String userDisplayName;
  final String userPhoneNumber;
  final String userEmail;
  final String error;

  const UpdateProfileState({
    this.viewStatus = ViewStatus.initial,
    required this.user,
    this.error = '',
    this.userDisplayName = '',
    this.userPhoneNumber = '',
    this.userEmail = '',
  });

  UpdateProfileState copyWith({
    ViewStatus? viewStatus,
    GNUser? user,
    String? error,
    String? userDisplayName,
    String? userPhoneNumber,
    String? userEmail,
  }) {
    return UpdateProfileState(
      viewStatus: viewStatus ?? this.viewStatus,
      user: user ?? this.user,
      error: error ?? '',
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  @override
  List<Object?> get props => [
        viewStatus,
        user,
        error,
        userDisplayName,
        userPhoneNumber,
        userEmail,
      ];
}
