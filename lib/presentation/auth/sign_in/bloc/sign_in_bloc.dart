import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/firebase/auth/gn_auth.dart';
import 'package:game_note/injection_container.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc() : super(const SignInState()) {
    on<SignInPhoneChanged>(_onPhoneChanged);
    on<SignInSubmitted>(_onSubmitted);

    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<EmailSignInSubmitted>(_onEmailSignInSubmitted);
  }

  _onEmailChanged(EmailChanged event, Emitter<SignInState> emit) async {
    // validate email
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(event.email)) {
      emit(state.copyWith(
          email: event.email, emailError: 'Vui lòng nhập email hợp lệ'));
      return;
    }
    emit(state.copyWith(email: event.email));
  }

  _onPasswordChanged(PasswordChanged event, Emitter<SignInState> emit) async {
    // validate password
    if (event.password.length < 6) {
      emit(state.copyWith(
          password: event.password,
          passwordError: 'Mật khẩu phải có ít nhất 6 ký tự'));
      return;
    }
    emit(state.copyWith(password: event.password));
  }

  _onEmailSignInSubmitted(
      EmailSignInSubmitted event, Emitter<SignInState> emit) async {
    if (state.status == SignInStatus.loading) return;

    // check valid input
    debugPrint('onEmailSignInSubmitted');
    if (state.email.isEmpty) {
      emit(state.copyWith(emailError: 'Vui lòng nhập email'));
      return;
    }
    if (state.password.isEmpty) {
      emit(state.copyWith(passwordError: 'Vui lòng nhập mật khẩu'));
      return;
    }
    if (state.emailError.isNotEmpty) {
      return;
    }
    if (state.passwordError.isNotEmpty) {
      return;
    }
    // do stuff
    emit(state.copyWith(status: SignInStatus.loading));
    //
    final email = state.email;
    final password = state.password;
    // do sign in with firebase
    try {
      await getIt<GNAuth>()
          .signInOrCreateUserWithEmailAndPassword(email, password);
      emit(state.copyWith(status: SignInStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (e is FirebaseAuthException) {
        String error = '';
        if (e.code == 'wrong-password') {
          error = 'Mật khẩu không đúng';
        } else if (e.code == 'too-many-requests') {
          error = 'Quá nhiều yêu cầu, vui lòng thử lại sau';
        } else if (e.code == 'user-not-found') {
          error = 'Email không tồn tại';
        } else {
          error = 'Đã có lỗi xảy ra';
        }
        emit(state.copyWith(status: SignInStatus.error, error: error));
        return;
      }
      emit(state.copyWith(status: SignInStatus.error, error: e.toString()));
    }
  }

  _onPhoneChanged(SignInPhoneChanged event, Emitter<SignInState> emit) async {
    emit(state.copyWith(phoneNumber: event.phone));
  }

  _onSubmitted(SignInSubmitted event, Emitter<SignInState> emit) async {
    // check valid input
    debugPrint('onSignInSubmitted');
    // do stuff
    emit(state.copyWith(status: SignInStatus.loading));
    //
    final phoneNumber = _formatPhoneNumber(state.phoneNumber);
    if (kDebugMode) {
      print(phoneNumber);
    }
    // do sign in with firebase
    try {
      await getIt<GNAuth>().verifyPhoneNumber(phoneNumber);
      emit(state.copyWith(status: SignInStatus.verify));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      emit(state.copyWith(status: SignInStatus.error, error: e.toString()));
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.startsWith('0')) {
      return phoneNumber.replaceFirst('0', '+84');
    } else {
      return '+84$phoneNumber';
    }
    // return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }
}
