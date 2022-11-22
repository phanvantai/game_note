import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc() : super(const SignInState()) {
    on<SignInEmailChanged>(_onEmailChanged);
    on<SignInPasswordChanged>(_onPasswordChanged);
    on<SignInSubmitted>(_onSubmitted);
  }

  _onEmailChanged(SignInEmailChanged event, Emitter<SignInState> emit) async {
    emit(state.copyWith(email: event.email));
    print(state);
  }

  _onPasswordChanged(
      SignInPasswordChanged event, Emitter<SignInState> emit) async {
    emit(state.copyWith(password: event.password));
    print(state);
  }

  _onSubmitted(SignInSubmitted event, Emitter<SignInState> emit) async {
    // check valid input
    print('onSignInSubmitted');
    // do stuff
  }
}
