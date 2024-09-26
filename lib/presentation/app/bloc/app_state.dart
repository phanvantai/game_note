part of 'app_bloc.dart';

enum AppStatus { unknown, authenticated }

extension AppStatusX on AppStatus {
  bool get isAuthenticated => this == AppStatus.authenticated;
}

class AppState extends Equatable {
  final AppStatus status;
  final bool enableFootballFeature;

  const AppState({
    this.status = AppStatus.unknown,
    this.enableFootballFeature = false,
  });

  AppState copyWith({
    AppStatus? status,
    bool? enableFootballFeature,
  }) {
    return AppState(
      status: status ?? this.status,
      enableFootballFeature:
          enableFootballFeature ?? this.enableFootballFeature,
    );
  }

  @override
  List<Object?> get props => [status, enableFootballFeature];
}
