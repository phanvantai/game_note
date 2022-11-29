part of 'app_bloc.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();
  @override
  List<Object?> get props => [];
}

class SwitchAppMode extends AppEvent {
  final AppStatus status;

  const SwitchAppMode(this.status);

  @override
  List<Object?> get props => [status];
}
