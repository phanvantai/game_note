import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/domain/usecases/sign_up_with_email.dart';

import '../../../../domain/entities/user_model.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final SignUpWithEmail signUpWithEmail;
  SignUpBloc({required this.signUpWithEmail}) : super(const SignUpState()) {
    on<SignUpEmailChanged>(_onEmailChanged);
    on<SignUpPasswordChanged>(_onPasswordChanged);
    on<SignUpConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<SignUpSubmitted>(_onSubmitted);
  }

  _onEmailChanged(SignUpEmailChanged event, Emitter<SignUpState> emit) async {
    emit(state.copyWith(email: event.email));
    _validateEmail(emit);
  }

  _onPasswordChanged(
      SignUpPasswordChanged event, Emitter<SignUpState> emit) async {
    emit(state.copyWith(password: event.password));
    _validatePassword(emit);
  }

  _onConfirmPasswordChanged(
      SignUpConfirmPasswordChanged event, Emitter<SignUpState> emit) async {
    emit(state.copyWith(confirmPassword: event.confirmPassword));
    _validateConfirmPassword(emit);
  }

  _onSubmitted(SignUpSubmitted event, Emitter<SignUpState> emit) async {
    // validate
    _validate(emit);

    if (state.status == SignUpStatus.valid) {
      emit(state.copyWith(status: SignUpStatus.loading));
      debugPrint(
          'signUpSubmitted ${state.email} ${state.password} ${state.confirmPassword}');
      // do sign up firebase
      //
      var abc = await signUpWithEmail
          .call(SignUpWithEmailParams(state.email, state.password));
      abc.when(
        (error) => emit(
            state.copyWith(status: SignUpStatus.error, error: error.message)),
        (success) => emit(
            state.copyWith(status: SignUpStatus.success, userModel: success)),
      );
    }
  }

  _validate(Emitter<SignUpState> emit) {
    // validate email
    _validateEmail(emit);
    // validate confirm password
    _validateConfirmPassword(emit);
    // validate password
    _validatePassword(emit);
  }

  _validateEmail(Emitter<SignUpState> emit) {
    if (state.email.isEmpty) {
      emit(state.copyWith(
        status: SignUpStatus.invalid,
        error: 'Email cannot be empty',
      ));
      return;
    }
    final regex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}");
    if (!regex.hasMatch(state.email.toLowerCase())) {
      emit(state.copyWith(
        status: SignUpStatus.invalid,
        error: 'Email is not correct',
      ));
      return;
    }
    emit(state.copyWith(
      status: SignUpStatus.valid,
    ));
  }

  _validatePassword(Emitter<SignUpState> emit) {
    if (state.password.isEmpty) {
      emit(state.copyWith(
        status: SignUpStatus.invalid,
        error: 'Password cannot be empty',
      ));
      return;
    }
    if (state.password.length < 6) {
      emit(state.copyWith(
        status: SignUpStatus.invalid,
        error: 'Password too short',
      ));
      return;
    }
    emit(state.copyWith(
      status: SignUpStatus.valid,
    ));
  }

  _validateConfirmPassword(Emitter<SignUpState> emit) {
    if (state.password != state.confirmPassword) {
      emit(state.copyWith(
        status: SignUpStatus.invalid,
        error: 'Confirm Password not match',
      ));
      return;
    }
    emit(state.copyWith(
      status: SignUpStatus.valid,
    ));
  }
}
