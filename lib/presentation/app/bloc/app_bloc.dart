import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppState()) {
    if (kDebugMode) {
      debugPrint('[AuthFlow] AppBloc.init: status=${state.status}');
    }
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<InitApp>(_onInitApp);
    on<UpdateFootballFeature>(_onUpdateFootballFeature);
  }

  void _onUpdateFootballFeature(
    UpdateFootballFeature event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(enableFootballFeature: event.enableFootballFeature));
  }

  void _onInitApp(InitApp event, Emitter<AppState> emit) {
    if (kDebugMode) {
      debugPrint('[AuthFlow] AppBloc.InitApp: status=${state.status}');
    }
  }

  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AppState> emit) {
    if (kDebugMode) {
      debugPrint(
        '[AuthFlow] AppBloc.AuthStatusChanged: '
        '${state.status} -> ${event.status}',
      );
    }
    emit(state.copyWith(status: event.status));
  }
}
