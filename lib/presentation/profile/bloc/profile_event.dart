part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {}

class SignOutProfileEvent extends ProfileEvent {}

class DeleteProfileEvent extends ProfileEvent {}
