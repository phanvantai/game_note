part of 'sign_in_bloc.dart';

enum SignInStatus { initial, loading, valid, invalid, error }

class SignInState extends Equatable {
  final SignInStatus status;
  final String email;
  final String password;

  const SignInState({
    this.status = SignInStatus.initial,
    this.email = '',
    this.password = '',
  });

  SignInState copyWith({
    SignInStatus? status,
    String? email,
    String? password,
  }) {
    return SignInState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  @override
  List<Object?> get props => [status, email, password];
}
