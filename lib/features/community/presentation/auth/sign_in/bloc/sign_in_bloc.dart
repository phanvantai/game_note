import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/domain/usecases/sign_in_with_email.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final SignInWithEmail signInWithEmail;
  SignInBloc({required this.signInWithEmail}) : super(const SignInState()) {
    on<SignInEmailChanged>(_onEmailChanged);
    on<SignInPasswordChanged>(_onPasswordChanged);
    on<SignInSubmitted>(_onSubmitted);
  }

  _onEmailChanged(SignInEmailChanged event, Emitter<SignInState> emit) async {
    emit(state.copyWith(email: event.email));
    debugPrint(state.toString());
  }

  _onPasswordChanged(
      SignInPasswordChanged event, Emitter<SignInState> emit) async {
    emit(state.copyWith(password: event.password));
    debugPrint(state.toString());
  }

  _onSubmitted(SignInSubmitted event, Emitter<SignInState> emit) async {
    // check valid input
    debugPrint('onSignInSubmitted');
    // do stuff
    // do sign in with firebase
    var abc = await signInWithEmail
        .call(SignInWithEmailParams(state.email, state.password));
    abc.when(
      (error) {
        print(error.message);
      },
      (success) {
        print(success);
      },
    );
  }
}
