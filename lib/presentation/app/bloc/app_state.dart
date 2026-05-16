part of 'app_bloc.dart';

/// Auth lifecycle states.
///
/// - [initializing]: app just booted, Firebase Auth hasn't emitted its first
///   restored-session event yet. We don't know if the user is signed in.
///   Routes are held on the splash screen so deep links don't fire data
///   queries with `currentUser == null` before auth resolves.
/// - [unauthenticated]: Firebase confirmed no signed-in user. Router
///   bounces protected routes to /login with a `?next` param.
/// - [authenticated]: a Firebase user is signed in.
enum AppStatus { initializing, unauthenticated, authenticated }

extension AppStatusX on AppStatus {
  bool get isAuthenticated => this == AppStatus.authenticated;
  bool get isInitializing => this == AppStatus.initializing;
}

class AppState extends Equatable {
  final AppStatus status;
  final bool enableFootballFeature;

  const AppState({
    this.status = AppStatus.initializing,
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
