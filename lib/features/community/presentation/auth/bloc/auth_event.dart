part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class SignInEmailEvent extends AuthEvent {}

class CreateAccountEvent extends AuthEvent {}

class InitialEvent extends AuthEvent {}
