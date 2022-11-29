import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/data/datasources/auth_datasource.dart';
import 'package:game_note/features/community/domain/entities/user_model.dart';
import 'package:game_note/injection_container.dart';

part 'community_event.dart';
part 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  CommunityBloc() : super(const CommunityState()) {
    on<LoginEvent>(_onLogin);
    on<SignOutEvent>(_onLogout);
    on<InitialComEvent>(_onInitial);
  }

  _onInitial(InitialComEvent event, Emitter<CommunityState> emit) {
    // check login state
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugPrint(user.toString());
      emit(state.copyWith(
        status: CommunityStatus.loggedIn,
        userModel: UserModel(uid: user.uid, email: user.email),
      ));
    }
  }

  _onLogin(LoginEvent event, Emitter<CommunityState> emit) {
    emit(state.copyWith(status: CommunityStatus.loggedIn));
  }

  _onLogout(SignOutEvent event, Emitter<CommunityState> emit) async {
    await getIt<AuthDatasource>().signOut();
    if (FirebaseAuth.instance.currentUser == null) {
      emit(state.copyWith(status: CommunityStatus.none));
    }
  }
}
