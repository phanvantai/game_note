part of 'app_bloc.dart';

/// Auth lifecycle states.
///
/// - [initializing]: app just booted, Firebase Auth hasn't emitted its first
///   restored-session event yet. We don't know if the user is signed in.
///   Routes are held on the splash screen so deep links don't fire data
///   queries with `currentUser == null` before auth resolves.
/// - [unauthenticated]: Firebase confirmed no signed-in user. Router
///   bounces protected routes to /login with a `?next` param.
/// - [profileIncomplete]: a Firebase user is signed in, but the app profile is
///   missing required display data.
/// - [authenticated]: a Firebase user is signed in and has a complete app
///   profile.
enum AppStatus {
  initializing,
  unauthenticated,
  profileIncomplete,
  authenticated,
}

extension AppStatusX on AppStatus {
  bool get isAuthenticated => this == AppStatus.authenticated;
  bool get isInitializing => this == AppStatus.initializing;
}

class AppState extends Equatable {
  final AppStatus status;
  final bool enableFootballFeature;
  final GNUser? currentUser;

  const AppState({
    this.status = AppStatus.initializing,
    this.enableFootballFeature = false,
    this.currentUser,
  });

  AppState copyWith({
    AppStatus? status,
    bool? enableFootballFeature,
    GNUser? currentUser,
    bool clearCurrentUser = false,
  }) {
    return AppState(
      status: status ?? this.status,
      enableFootballFeature:
          enableFootballFeature ?? this.enableFootballFeature,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
    );
  }

  @override
  List<Object?> get props => [status, enableFootballFeature, currentUser];
}
