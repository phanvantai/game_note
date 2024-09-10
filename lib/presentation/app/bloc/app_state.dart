part of 'app_bloc.dart';

enum AppStatus { unknown, authenticated }

extension AppStatusX on AppStatus {
  bool get isAuthenticated => this == AppStatus.authenticated;
}

class AppState extends Equatable {
  final AppStatus status;

  const AppState({
    this.status = AppStatus.unknown,
  });

  AppState copyWith({
    AppStatus? status,
  }) {
    return AppState(
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [status];
}
