import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pes_arena/core/databases/province.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppState()) {
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<InitApp>(_onInitApp);
    on<UpdateFootballFeature>(_onUpdateFootballFeature);
  }

  _onUpdateFootballFeature(
      UpdateFootballFeature event, Emitter<AppState> emit) {
    emit(state.copyWith(enableFootballFeature: event.enableFootballFeature));
  }

  _onInitApp(InitApp event, Emitter<AppState> emit) {
    // Do something
    getProvinces();
  }

  _onAuthStatusChanged(AuthStatusChanged event, Emitter<AppState> emit) {
    emit(state.copyWith(status: event.status));
  }
}
