import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/domain/repositories/user_repository.dart';

import '../../../../core/common/view_status.dart';
import '../../../../firebase/firestore/user/gn_user.dart';

part 'update_profile_event.dart';
part 'update_profile_state.dart';

class UpdateProfileBloc extends Bloc<UpdateProfileEvent, UpdateProfileState> {
  final UserRepository _userRepository;
  UpdateProfileBloc(this._userRepository, GNUser? user)
      : super(UpdateProfileState(user: user)) {
    on<SubmittUpdateProfile>(_submittUpdateProfile);
  }

  void _submittUpdateProfile(
      SubmittUpdateProfile event, Emitter<UpdateProfileState> emit) async {
    if (state.viewStatus.isLoading) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));

    // validate user input
    if (event.userDisplayName.isEmpty) {
      emit(state.copyWith(
        viewStatus: ViewStatus.failure,
        error: 'Tên hiển thị không được để trống',
      ));
      return;
    }

    // if (event.userPhoneNumber.isEmpty) {
    //   emit(state.copyWith(
    //     viewStatus: ViewStatus.failure,
    //     errorPhoneNumber: 'Số điện thoại không được để trống',
    //   ));
    //   return;
    // }

    if (event.userEmail.isEmpty) {
      emit(state.copyWith(
        viewStatus: ViewStatus.failure,
        error: 'Email không được để trống',
      ));
      return;
    }

    // check regex email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(event.userEmail)) {
      emit(state.copyWith(
        viewStatus: ViewStatus.failure,
        error: 'Email không hợp lệ',
      ));
      return;
    }

    // update profile
    await _userRepository
        .updateProfile(
      displayName: event.userDisplayName,
      phoneNumber: event.userPhoneNumber,
      email: event.userEmail,
    )
        .then((_) {
      emit(state.copyWith(viewStatus: ViewStatus.success));
    }).catchError((e) {
      emit(state.copyWith(viewStatus: ViewStatus.failure, error: e.toString()));
    });
  }
}
