import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileState()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<SignOutProfileEvent>(_onSignOut);
    on<DeleteProfileEvent>(_onDeleteProfile);
  }

  _onLoadProfile(LoadProfileEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(state.copyWith(viewStatus: ViewStatus.success, user: user));
      } else {
        emit(state.copyWith(viewStatus: ViewStatus.failure));
      }
    } catch (e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure, error: e.toString()));
    }
  }

  _onSignOut(SignOutProfileEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await FirebaseAuth.instance.signOut();
      emit(state.copyWith(viewStatus: ViewStatus.success));
    } catch (e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure, error: e.toString()));
    }
  }

  _onDeleteProfile(DeleteProfileEvent event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        emit(state.copyWith(viewStatus: ViewStatus.success));
      } else {
        emit(state.copyWith(viewStatus: ViewStatus.failure));
      }
    } catch (e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure, error: e.toString()));
    }
  }
}
