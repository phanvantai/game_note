part of 'sign_up_bloc.dart';

enum SignUpStatus { initial, loading, valid, invalid, error, success }

class SignUpState extends Equatable {
  final SignUpStatus status;
  final String email;
  final String password;
  final String confirmPassword;
  final String error;
  final UserModel? userModel;

  const SignUpState({
    this.status = SignUpStatus.initial,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.error = '',
    this.userModel,
  });

  SignUpState copyWith({
    SignUpStatus? status,
    String? email,
    String? password,
    String? confirmPassword,
    String? error,
    UserModel? userModel,
  }) {
    return SignUpState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      error: error ?? '',
      userModel: userModel ?? this.userModel,
    );
  }

  @override
  List<Object?> get props =>
      [status, email, password, confirmPassword, error, userModel];
}
