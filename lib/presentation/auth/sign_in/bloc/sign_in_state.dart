part of 'sign_in_bloc.dart';

enum SignInStatus { initial, loading, verify, invalid, error, success }

class SignInState extends Equatable {
  final SignInStatus status;
  final String phoneNumber;
  final String error;

  const SignInState({
    this.status = SignInStatus.initial,
    this.phoneNumber = '',
    this.error = '',
  });

  SignInState copyWith({
    SignInStatus? status,
    String? phoneNumber,
    String? error,
  }) {
    return SignInState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, phoneNumber, error];
}
