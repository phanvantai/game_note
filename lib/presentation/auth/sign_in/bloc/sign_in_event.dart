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
