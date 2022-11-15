part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  signInMail,
  signUpMail,
}

extension AuthStatusX on AuthStatus {
  bool get isInitial => this == AuthStatus.initial;
  bool get isSignIn => this == AuthStatus.signInMail;
  bool get isSignUp => this == AuthStatus.signUpMail;
}

class AuthState extends Equatable {
  final AuthStatus status;

  const AuthState({
    this.status = AuthStatus.initial,
  });

  AuthState copyWith({
    AuthStatus? status,
  }) {
    return AuthState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [];
}
