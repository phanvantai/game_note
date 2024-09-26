part of 'update_profile_bloc.dart';

abstract class UpdateProfileEvent extends Equatable {
  const UpdateProfileEvent();

  @override
  List<Object> get props => [];
}

class SubmittUpdateProfile extends UpdateProfileEvent {
  final String userDisplayName;
  final String userPhoneNumber;
  final String userEmail;

  const SubmittUpdateProfile({
    required this.userDisplayName,
    required this.userPhoneNumber,
    required this.userEmail,
  });

  @override
  List<Object> get props => [userDisplayName, userPhoneNumber, userEmail];
}
