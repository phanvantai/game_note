import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/firebase/auth/gn_auth.dart';
import 'package:game_note/injection_container.dart';

part 'third_party_event.dart';
part 'third_party_state.dart';

class ThirdPartyBloc extends Bloc<ThirdPartyEvent, ThirdPartyState> {
  ThirdPartyBloc() : super(const ThirdPartyState()) {
    on<ThirdPartySignInGoogle>(_signInGoogle);
    on<ThirdPartySignInApple>(_signInApple);
  }

  final GNAuth _auth = getIt<GNAuth>();

  void _signInGoogle(
      ThirdPartySignInGoogle event, Emitter<ThirdPartyState> emit) async {
    if (state.status == ViewStatus.loading) {
      return;
    }

    if (kDebugMode) {
      print('🚀 Starting Google Sign-In process...');
    }

    emit(state.copyWith(status: ViewStatus.loading));
    try {
      if (kDebugMode) {
        print('📱 Calling _auth.signInWithGoogle()...');
      }

      final result = await _auth.signInWithGoogle();

      if (kDebugMode) {
        print('✅ Google Sign-In successful!');
        print('👤 User: ${result.user?.displayName}');
        print('📧 Email: ${result.user?.email}');
        print('🆔 UID: ${result.user?.uid}');
      }

      emit(state.copyWith(status: ViewStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Sign-In failed with error:');
        print('🔍 Error type: ${e.runtimeType}');
        print('💬 Error message: $e');

        if (e is FirebaseAuthException) {
          print('🔥 Firebase Auth Error Details:');
          print('   - Code: ${e.code}');
          print('   - Message: ${e.message}');
          print('   - Plugin: ${e.plugin}');
        }
      }

      if (e is FirebaseAuthException && e.code == 'ERROR_ABORTED_BY_USER') {
        if (kDebugMode) {
          print('🚫 User cancelled Google Sign-In');
        }
        emit(state.copyWith(status: ViewStatus.initial));
        return;
      }

      emit(state.copyWith(status: ViewStatus.failure, error: e.toString()));
    }
  }

  void _signInApple(
      ThirdPartySignInApple event, Emitter<ThirdPartyState> emit) async {
    if (state.status == ViewStatus.loading) {
      return;
    }
    emit(state.copyWith(status: ViewStatus.loading));
    try {
      final result = await _auth.signInWithApple();
      if (kDebugMode) {
        print(result.user?.displayName);
      }
      emit(state.copyWith(status: ViewStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }

      if (e is FirebaseAuthException &&
          (e.code == 'ERROR_ABORTED_BY_USER' || e.code == 'canceled')) {
        emit(state.copyWith(status: ViewStatus.initial));
        return;
      }
      emit(state.copyWith(status: ViewStatus.failure, error: e.toString()));
    }
  }
}
