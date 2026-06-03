import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/injection_container.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc({GNAuth? auth})
    : _auth = auth ?? getIt<GNAuth>(),
      super(const SignInState()) {
    on<AuthFormModeChanged>(_onModeChanged);
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<AuthFormSubmitted>(_onAuthFormSubmitted);
    on<EmailSignInSubmitted>((event, emit) {
      add(AuthFormSubmitted());
    });
  }

  final GNAuth _auth;

  Future<void> _onModeChanged(
    AuthFormModeChanged event,
    Emitter<SignInState> emit,
  ) async {
    emit(
      state.copyWith(
        mode: event.mode,
        status: SignInStatus.initial,
        emailError: '',
        passwordError: '',
      ),
    );
  }

  Future<void> _onEmailChanged(
    EmailChanged event,
    Emitter<SignInState> emit,
  ) async {
    emit(state.copyWith(email: event.email, emailError: ''));
  }

  Future<void> _onPasswordChanged(
    PasswordChanged event,
    Emitter<SignInState> emit,
  ) async {
    emit(state.copyWith(password: event.password, passwordError: ''));
  }

  Future<void> _onAuthFormSubmitted(
    AuthFormSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    if (state.status == SignInStatus.loading) return;

    final emailError = _emailError(state.email);
    final passwordError = state.mode == AuthFormMode.resetPassword
        ? ''
        : _passwordError(state.password);
    if (emailError.isNotEmpty || passwordError.isNotEmpty) {
      emit(
        state.copyWith(
          status: SignInStatus.invalid,
          emailError: emailError,
          passwordError: passwordError,
        ),
      );
      return;
    }

    emit(state.copyWith(status: SignInStatus.loading));
    final email = state.email.trim();
    final password = state.password;
    try {
      switch (state.mode) {
        case AuthFormMode.signIn:
          await _auth.signInWithEmailAndPassword(email, password);
        case AuthFormMode.register:
          await _auth.createUserWithEmailAndPassword(email, password);
        case AuthFormMode.resetPassword:
          await _auth.sendPasswordResetEmail(email);
      }
      emit(state.copyWith(status: SignInStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (e is FirebaseAuthException) {
        String error = '';
        error = _firebaseAuthErrorMessage(e);
        emit(state.copyWith(status: SignInStatus.error, error: error));
        return;
      }
      emit(state.copyWith(status: SignInStatus.error, error: e.toString()));
    }
  }

  String _emailError(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'Vui lòng nhập email';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(trimmed)) return 'Vui lòng nhập email hợp lệ';
    return '';
  }

  String _passwordError(String password) {
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (password.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return '';
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException e) {
    if (e.code == 'wrong-password') {
      return 'Mật khẩu không đúng';
    }
    if (e.code == 'too-many-requests') {
      return 'Quá nhiều yêu cầu, vui lòng thử lại sau';
    }
    if (e.code == 'user-not-found') {
      return 'Email không tồn tại';
    }
    if (e.code == 'email-already-in-use') {
      return 'Email đã được sử dụng';
    }
    if (e.code == 'invalid-email') {
      return 'Email không hợp lệ';
    }
    if (e.code == 'weak-password') {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return 'Đã có lỗi xảy ra';
  }
}
