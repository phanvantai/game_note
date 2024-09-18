part of 'sign_in_bloc.dart';

abstract class SignInEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SignInPhoneChanged extends SignInEvent {
  final String phone;

  SignInPhoneChanged(this.phone);

  @override
  List<Object?> get props => [phone];
}

class SignInSubmitted extends SignInEvent {}

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

class EmailSignInSubmitted extends SignInEvent {}
