import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'community_event.dart';
part 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  CommunityBloc() : super(const CommunityState()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  _onLogin(LoginEvent event, Emitter<CommunityState> emit) {
    emit(state.copyWith(status: CommunityStatus.loggedIn));
  }

  _onLogout(LogoutEvent event, Emitter<CommunityState> emit) {
    emit(state.copyWith(status: CommunityStatus.none));
  }
}
