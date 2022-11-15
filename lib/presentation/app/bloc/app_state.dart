part of 'app_bloc.dart';

enum AppStatus { none, community, offline }

extension AppStatusX on AppStatus {
  bool get isCommunity => this == AppStatus.community;
  bool get isOffline => this == AppStatus.offline;
}

class AppState extends Equatable {
  final AppStatus status;

  const AppState({
    this.status = AppStatus.none,
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
