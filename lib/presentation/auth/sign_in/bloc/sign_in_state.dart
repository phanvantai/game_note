part of 'sign_in_bloc.dart';

enum SignInStatus { initial, loading, verify, invalid, error, success }

class SignInState extends Equatable {
  final SignInStatus status;
  final String phoneNumber;
  final String email;
  final String password;
  final String emailError;
  final String passwordError;
  final String error;

  const SignInState({
    this.status = SignInStatus.initial,
    this.phoneNumber = '',
    this.error = '',
    this.email = '',
    this.password = '',
    this.emailError = '',
    this.passwordError = '',
  });

  SignInState copyWith({
    SignInStatus? status,
    String? phoneNumber,
    String? error,
    String? email,
    String? password,
    String? emailError,
    String? passwordError,
  }) {
    return SignInState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      error: error ?? '',
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: emailError ?? '',
      passwordError: passwordError ?? '',
    );
  }

  @override
  List<Object?> get props => [
        status,
        phoneNumber,
        error,
        email,
        password,
        emailError,
        passwordError,
      ];
}
