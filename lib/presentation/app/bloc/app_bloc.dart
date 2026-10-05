import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pes_arena/domain/repositories/user_repository.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/service/permission_util.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    GNAuth? auth,
    UserRepository? userRepository,
    PermissionUtil? permissionUtil,
  }) : _auth = auth,
       _userRepository = userRepository,
       _permissionUtil = permissionUtil,
       super(const AppState()) {
    if (kDebugMode) {
      debugPrint('[AuthFlow] AppBloc.init: status=${state.status}');
    }
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<InitApp>(_onInitApp);
    on<_FirebaseAuthUserChanged>(_onFirebaseAuthUserChanged);
    on<RefreshCurrentUser>(_onRefreshCurrentUser);

    _ensureAuthSubscription();
  }

  GNAuth? _auth;
  UserRepository? _userRepository;
  PermissionUtil? _permissionUtil;
  StreamSubscription<User?>? _authSubscription;
  User? _lastFirebaseUser;

  void _onInitApp(InitApp event, Emitter<AppState> emit) {
    if (kDebugMode) {
      debugPrint('[AuthFlow] AppBloc.InitApp: status=${state.status}');
    }
    _ensureAuthSubscription();
  }

  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AppState> emit) {
    if (kDebugMode) {
      debugPrint(
        '[AuthFlow] AppBloc.AuthStatusChanged: '
        '${state.status} -> ${event.status}',
      );
    }
    emit(state.copyWith(status: event.status));
  }

  void _ensureAuthSubscription() {
    if (_authSubscription != null) return;

    _auth ??= getIt.isRegistered<GNAuth>() ? getIt<GNAuth>() : null;
    _userRepository ??= getIt.isRegistered<UserRepository>()
        ? getIt<UserRepository>()
        : null;
    _permissionUtil ??= getIt.isRegistered<PermissionUtil>()
        ? getIt<PermissionUtil>()
        : null;

    final auth = _auth;
    if (auth == null || _userRepository == null || _permissionUtil == null) {
      if (kDebugMode) {
        debugPrint('[AuthFlow] AppBloc: auth services not ready, skip listen');
      }
      return;
    }

    _authSubscription = auth.authStateChanges().listen((user) {
      add(_FirebaseAuthUserChanged(user));
    });
  }

  Future<void> _onFirebaseAuthUserChanged(
    _FirebaseAuthUserChanged event,
    Emitter<AppState> emit,
  ) async {
    _lastFirebaseUser = event.user;
    await _loadFirebaseUser(event.user, emit);
  }

  Future<void> _onRefreshCurrentUser(
    RefreshCurrentUser event,
    Emitter<AppState> emit,
  ) async {
    await _loadFirebaseUser(_lastFirebaseUser, emit);
  }

  Future<void> _loadFirebaseUser(User? user, Emitter<AppState> emit) async {
    if (kDebugMode) {
      debugPrint(
        '[AuthFlow] AppBloc.loadFirebaseUser: uid=${user?.uid} email=${user?.email}',
      );
    }

    if (user == null) {
      _permissionUtil?.setCurrentUser(null);
      emit(
        state.copyWith(
          status: AppStatus.unauthenticated,
          clearCurrentUser: true,
        ),
      );
      return;
    }

    try {
      final userRepository = _userRepository!;
      final permissionUtil = _permissionUtil!;
      final currentUser = await userRepository.ensureCurrentUser(user);
      permissionUtil.setCurrentUser(currentUser);
      _auth?.checkLoginMethod();
      final hasDisplayName =
          currentUser.displayName != null &&
          currentUser.displayName!.trim().isNotEmpty;
      emit(
        state.copyWith(
          status: hasDisplayName
              ? AppStatus.authenticated
              : AppStatus.profileIncomplete,
          currentUser: currentUser,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthFlow] AppBloc.loadFirebaseUser failed: $e');
      }
      _permissionUtil?.setCurrentUser(null);
      emit(
        state.copyWith(
          status: AppStatus.unauthenticated,
          clearCurrentUser: true,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
