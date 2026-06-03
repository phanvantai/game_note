part of 'sign_in_bloc.dart';

abstract class SignInEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthFormModeChanged extends SignInEvent {
  final AuthFormMode mode;

  AuthFormModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

class EmailChanged extends SignInEvent {
  final String email;

  EmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

class PasswordChanged extends SignInEvent {
  final String password;

  PasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class AuthFormSubmitted extends SignInEvent {}

class EmailSignInSubmitted extends SignInEvent {}
