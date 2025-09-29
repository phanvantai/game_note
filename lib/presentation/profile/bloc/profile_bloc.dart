import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/domain/repositories/user_repository.dart';

import '../../../firebase/firestore/user/gn_user.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository _userRepository;
  ProfileBloc(this._userRepository) : super(const ProfileState()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<SignOutProfileEvent>(_onSignOut);
    on<DeleteProfileEvent>(_onDeleteProfile);

    on<ChangeAvatarProfileEvent>(_onChangeAvatar);
    on<DeleteAvatarProfileEvent>(_onDeleteAvatar);
  }

  _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final user = await _userRepository.loadProfile();
      emit(state.copyWith(viewStatus: ViewStatus.success, user: user));
    } catch (e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure, error: e.toString()));
    }
  }

  _onSignOut(SignOutProfileEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _userRepository.signOut();
      emit(state.copyWith(viewStatus: ViewStatus.success));
    } catch (e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure, error: e.toString()));
    }
  }

  _onDeleteProfile(DeleteProfileEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _userRepository.deleteAccount();
    } catch (e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure, error: e.toString()));
    }
  }

  _onChangeAvatar(
      ChangeAvatarProfileEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _userRepository.changeAvatar();
      add(LoadProfileEvent());
    } catch (e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure, error: e.toString()));
    }
  }

  _onDeleteAvatar(
      DeleteAvatarProfileEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _userRepository.deleteAvatar();
      add(LoadProfileEvent());
    } catch (e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure, error: e.toString()));
    }
  }
}
