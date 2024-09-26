part of 'change_password_bloc.dart';

abstract class ChangePasswordEvent extends Equatable {
  const ChangePasswordEvent();

  @override
  List<Object> get props => [];
}

class OldPasswordChanged extends ChangePasswordEvent {
  final String value;

  const OldPasswordChanged(this.value);

  @override
  List<Object> get props => [value];
}

class NewPasswordChanged extends ChangePasswordEvent {
  final String value;

  const NewPasswordChanged(this.value);

  @override
  List<Object> get props => [value];
}

class ConfirmPasswordChanged extends ChangePasswordEvent {
  final String value;

  const ConfirmPasswordChanged(this.value);

  @override
  List<Object> get props => [value];
}

class ChangePasswordSubmitted extends ChangePasswordEvent {
  const ChangePasswordSubmitted();

  @override
  List<Object> get props => [];
}
