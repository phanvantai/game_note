import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/domain/repositories/user_repository.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';

class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final UserRepository _userRepository;
  ChangePasswordBloc(this._userRepository)
      : super(const ChangePasswordState()) {
    on<ChangePasswordSubmitted>(_onChangePasswordSubmitted);

    on<OldPasswordChanged>(_onOldPasswordChanged);
    on<NewPasswordChanged>(_onNewPasswordChanged);
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged);
  }

  void _onOldPasswordChanged(
      OldPasswordChanged event, Emitter<ChangePasswordState> emit) async {
    String error = '';
    if (event.value.isEmpty) {
      error = 'Mật khẩu không được để trống';
    } else if (event.value.length < 6) {
      error = 'Mật khẩu phải có độ dài lớn hơn hoặc bằng 6 kí tự';
    }
    emit(state.copyWith(oldPassword: event.value, errorOldPassword: error));
  }

  void _onNewPasswordChanged(
      NewPasswordChanged event, Emitter<ChangePasswordState> emit) async {
    String error = '';
    if (event.value.isEmpty) {
      error = 'Mật khẩu không được để trống';
    } else if (event.value.length < 6) {
      error = 'Mật khẩu phải có độ dài lớn hơn hoặc bằng 6 kí tự';
    }
    emit(state.copyWith(newPassword: event.value, errorNewPassword: error));
  }

  void _onConfirmPasswordChanged(
      ConfirmPasswordChanged event, Emitter<ChangePasswordState> emit) async {
    String error = '';
    if (event.value.isEmpty) {
      error = 'Mật khẩu không được để trống';
    } else if (event.value.length < 6) {
      error = 'Mật khẩu phải có độ dài lớn hơn hoặc bằng 6 kí tự';
    } else if (event.value != state.newPassword) {
      error = 'Mật khẩu xác nhận không khớp';
    }
    emit(state.copyWith(
        confirmPassword: event.value, errorConfirmPassword: error));
  }

  void _onChangePasswordSubmitted(
      ChangePasswordSubmitted event, Emitter<ChangePasswordState> emit) async {
    if (state.viewStatus == ViewStatus.loading) return;
    if (state.notValidForm) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    try {
      await _userRepository.changePassword(
          state.oldPassword, state.newPassword);
      emit(state.copyWith(viewStatus: ViewStatus.success));
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password') {
          emit(state.copyWith(
            viewStatus: ViewStatus.failure,
            errorMessage: 'Mật khẩu hiện tại không đúng',
          ));
        } else {
          emit(state.copyWith(
            viewStatus: ViewStatus.failure,
            errorMessage: e.toString(),
          ));
        }

        return;
      }
      emit(state.copyWith(
        viewStatus: ViewStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
