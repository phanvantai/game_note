part of 'app_bloc.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();
  @override
  List<Object?> get props => [];
}

class InitApp extends AppEvent {}

class AuthStatusChanged extends AppEvent {
  final AppStatus status;

  const AuthStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class UpdateFootballFeature extends AppEvent {
  final bool enableFootballFeature;

  const UpdateFootballFeature(this.enableFootballFeature);

  @override
  List<Object?> get props => [enableFootballFeature];
}
