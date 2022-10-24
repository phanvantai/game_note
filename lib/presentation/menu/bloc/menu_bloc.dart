import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_event.dart';
part 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc() : super(const MenuState()) {
    on<MembersEvent>(_onShowMembers);
    on<ShowMenuEvent>(_onShowMenu);
  }

  _onShowMembers(MembersEvent event, Emitter<MenuState> emit) {
    emit(state.copyWith(status: MenuStatus.members));
  }

  _onShowMenu(ShowMenuEvent event, Emitter<MenuState> emit) {
    emit(state.copyWith(status: MenuStatus.menu));
  }
}
