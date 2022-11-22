import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<SignInEmailEvent>(_onSignInEmail);
    on<CreateAccountEvent>(_onCreateAccount);
    on<InitialEvent>(_onInitial);
  }

  _onInitial(InitialEvent event, Emitter<AuthState> emit) async {
    emit(const AuthState());
  }

  _onSignInEmail(SignInEmailEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.signInMail));
  }

  _onCreateAccount(CreateAccountEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.createAccount));
  }
}
