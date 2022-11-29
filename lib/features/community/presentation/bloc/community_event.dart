part of 'community_bloc.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();
  @override
  List<Object?> get props => [];
}

class InitialComEvent extends CommunityEvent {}

class LoginEvent extends CommunityEvent {
  final UserModel userModel;

  const LoginEvent(this.userModel);
  @override
  List<Object?> get props => [userModel];
}

class SignOutEvent extends CommunityEvent {}
