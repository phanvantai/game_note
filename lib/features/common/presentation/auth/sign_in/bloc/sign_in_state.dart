part of 'sign_in_bloc.dart';

enum SignInStatus { initial, loading, verify, invalid, error, success }

class SignInState extends Equatable {
  final SignInStatus status;
  final String phoneNumber;
  final String error;
  final UserModel? userModel;

  const SignInState({
    this.status = SignInStatus.initial,
    this.phoneNumber = '',
    this.error = '',
    this.userModel,
  });

  SignInState copyWith({
    SignInStatus? status,
    String? phoneNumber,
    String? error,
    UserModel? userModel,
  }) {
    return SignInState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      error: error ?? this.error,
      userModel: userModel ?? this.userModel,
    );
  }

  @override
  List<Object?> get props => [status, phoneNumber, error, userModel];
}
