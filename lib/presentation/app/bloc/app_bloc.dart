import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppState()) {
    on<SwitchAppMode>(_onSwitchAppMode);
  }

  _onSwitchAppMode(SwitchAppMode event, Emitter<AppState> emit) {
    emit(state.copyWith(status: event.status));
  }
}
