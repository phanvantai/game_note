part of 'sign_in_bloc.dart';

enum SignInStatus { initial, loading, valid, invalid, error, success }

class SignInState extends Equatable {
  final SignInStatus status;
  final String email;
  final String password;
  final String error;
  final UserModel? userModel;

  const SignInState({
    this.status = SignInStatus.initial,
    this.email = '',
    this.password = '',
    this.error = '',
    this.userModel,
  });

  SignInState copyWith({
    SignInStatus? status,
    String? email,
    String? password,
    String? error,
    UserModel? userModel,
  }) {
    return SignInState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      error: error ?? this.error,
      userModel: userModel ?? this.userModel,
    );
  }

  @override
  List<Object?> get props => [status, email, password, error, userModel];
}
