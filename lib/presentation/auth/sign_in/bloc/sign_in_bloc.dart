import 'package:equatable/equatable.dart';
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
