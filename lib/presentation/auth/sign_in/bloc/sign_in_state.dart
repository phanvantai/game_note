part of 'sign_in_bloc.dart';

enum SignInStatus { initial, loading, invalid, error, success }

enum AuthFormMode { signIn, register, resetPassword }

class SignInState extends Equatable {
  final SignInStatus status;
  final AuthFormMode mode;
  final String email;
  final String password;
  final String emailError;
  final String passwordError;
  final String error;

  const SignInState({
    this.status = SignInStatus.initial,
    this.mode = AuthFormMode.signIn,
    this.error = '',
    this.email = '',
    this.password = '',
    this.emailError = '',
    this.passwordError = '',
  });

  SignInState copyWith({
    SignInStatus? status,
    AuthFormMode? mode,
    String? error,
    String? email,
    String? password,
    String? emailError,
    String? passwordError,
  }) {
    return SignInState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
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
    mode,
    error,
    email,
    password,
    emailError,
    passwordError,
  ];
}
