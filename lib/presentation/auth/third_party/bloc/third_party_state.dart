part of 'third_party_bloc.dart';

class ThirdPartyState extends Equatable {
  final ViewStatus status;
  final String error;

  const ThirdPartyState({
    this.status = ViewStatus.initial,
    this.error = '',
  });

  ThirdPartyState copyWith({
    ViewStatus? status,
    String? error,
  }) {
    return ThirdPartyState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, error];
}
