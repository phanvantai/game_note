import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';

import '../../../domain/repositories/user_repository.dart';
import '../../../firebase/firestore/user/gn_user.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;
  UserBloc(this._userRepository) : super(const UserState()) {
    on<SearchUser>(_onSearchUser);
  }

  Future<void> _onSearchUser(SearchUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final users = await _userRepository.searchUser(event.query);
      emit(state.copyWith(viewStatus: ViewStatus.success, users: users));
    } catch (e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure));
    }
  }
}
