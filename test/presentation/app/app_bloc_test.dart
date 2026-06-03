import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:pes_arena/service/permission_util.dart';

class _MockGNAuth extends Mock implements GNAuth {}

class _MockFirebaseUser extends Mock implements User {}

class _FlakyFirestore extends GNFirestore {
  _FlakyFirestore([super.firestore]);

  var _callCount = 0;

  @override
  FirebaseFirestore get firestore {
    _callCount += 1;
    if (_callCount > 1) {
      throw Exception('Firestore failed');
    }
    return super.firestore;
  }
}

User _firebaseUser({
  required String uid,
  String? displayName,
  String? email = 'player@example.com',
}) {
  final user = _MockFirebaseUser();
  when(() => user.uid).thenReturn(uid);
  when(() => user.displayName).thenReturn(displayName);
  when(() => user.email).thenReturn(email);
  when(() => user.phoneNumber).thenReturn(null);
  when(() => user.photoURL).thenReturn(null);
  return user;
}

void main() {
  StreamController<User?>? authController;
  bool shouldCloseAuthController = false;
  late _MockGNAuth auth;
  late GNFirestore firestore;
  late PermissionUtil permissionUtil;
  final List<AppBloc> trackedBlocs = [];

  void clearGetItDependencies() {
    if (getIt.isRegistered<GNAuth>()) {
      getIt.unregister<GNAuth>();
    }
    if (getIt.isRegistered<GNFirestore>()) {
      getIt.unregister<GNFirestore>();
    }
    if (getIt.isRegistered<PermissionUtil>()) {
      getIt.unregister<PermissionUtil>();
    }
  }

  setUp(() {
    clearGetItDependencies();
    authController = null;
    shouldCloseAuthController = false;
    auth = _MockGNAuth();
    firestore = GNFirestore(FakeFirebaseFirestore());
    permissionUtil = PermissionUtil();
    trackedBlocs.clear();
  });

  tearDown(() async {
    clearGetItDependencies();
    for (final bloc in List<AppBloc>.from(trackedBlocs)) {
      await bloc.close();
    }
    trackedBlocs.clear();
    if (shouldCloseAuthController && authController != null) {
      await authController?.close();
    }
  });

  Future<AppBloc> buildBloc({GNFirestore? firestoreOverride}) async {
    authController ??= StreamController<User?>();
    shouldCloseAuthController = true;
    when(
      () => auth.authStateChanges(),
    ).thenAnswer((_) => authController!.stream);
    final bloc = AppBloc(
      auth: auth,
      firestore: firestoreOverride ?? firestore,
      permissionUtil: permissionUtil,
    );
    trackedBlocs.add(bloc);
    return bloc;
  }

  test('emits unauthenticated when Firebase Auth emits null', () async {
    final bloc = await buildBloc();

    authController!.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, AppStatus.unauthenticated);
    expect(bloc.state.currentUser, isNull);
  });

  test(
    'emits profileIncomplete when signed-in user has no display name',
    () async {
      final bloc = await buildBloc();

      authController!.add(_firebaseUser(uid: 'user-1'));
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(bloc.state.status, AppStatus.profileIncomplete);
      expect(bloc.state.currentUser?.id, 'user-1');
      expect(bloc.state.currentUser?.displayName, isNull);
    },
  );

  test('emits authenticated when signed-in user has display name', () async {
    final bloc = await buildBloc();

    authController!.add(_firebaseUser(uid: 'user-2', displayName: 'Tai'));
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(bloc.state.status, AppStatus.authenticated);
    expect(bloc.state.currentUser, isA<GNUser>());
    expect(bloc.state.currentUser?.displayName, 'Tai');
  });

  test('can reload current profile after profile completion', () async {
    final bloc = await buildBloc();

    authController!.add(_firebaseUser(uid: 'user-3'));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(bloc.state.status, AppStatus.profileIncomplete);

    await firestore.firestore
        .collection(GNUser.collectionName)
        .doc('user-3')
        .update({GNUser.displayNameKey: 'Completed Player'});
    bloc.add(RefreshCurrentUser());
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(bloc.state.status, AppStatus.authenticated);
    expect(bloc.state.currentUser?.displayName, 'Completed Player');
  });

  test('handles InitApp when required services are not registered', () {
    clearGetItDependencies();
    final bloc = AppBloc();
    trackedBlocs.add(bloc);

    expect(bloc.state.status, AppStatus.initializing);

    bloc.add(InitApp());

    expect(bloc.state.status, AppStatus.initializing);
  });

  test('resolves GNAuth/GNFirestore/PermissionUtil from getIt and emits '
      'profileIncomplete and authenticated states', () async {
    authController = StreamController<User?>();
    shouldCloseAuthController = true;
    when(
      () => auth.authStateChanges(),
    ).thenAnswer((_) => authController!.stream);

    getIt.registerSingleton<GNAuth>(auth);
    getIt.registerSingleton<GNFirestore>(firestore);
    getIt.registerSingleton<PermissionUtil>(permissionUtil);

    final bloc = AppBloc();
    trackedBlocs.add(bloc);

    authController!.add(_firebaseUser(uid: 'user-initial'));
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(bloc.state.status, AppStatus.profileIncomplete);
    expect(bloc.state.currentUser?.id, 'user-initial');

    authController!.add(
      _firebaseUser(uid: 'user-authenticated', displayName: 'Tai'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(bloc.state.status, AppStatus.authenticated);
    expect(bloc.state.currentUser?.id, 'user-authenticated');
    expect(bloc.state.currentUser?.displayName, 'Tai');
  });

  test('updates status from AuthStatusChanged event', () async {
    final bloc = await buildBloc();

    bloc.add(AuthStatusChanged(AppStatus.profileIncomplete));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, AppStatus.profileIncomplete);
  });

  test(
    'updates football feature flag from UpdateFootballFeature event',
    () async {
      final bloc = await buildBloc();

      bloc.add(UpdateFootballFeature(true));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.enableFootballFeature, isTrue);

      bloc.add(UpdateFootballFeature(false));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.enableFootballFeature, isFalse);
    },
  );

  test('AppEvent props: InitApp has no props', () {
    expect(InitApp().props, isEmpty);
  });

  test('AppEvent props: AuthStatusChanged exposes status', () {
    expect(
      AuthStatusChanged(AppStatus.authenticated).props,
      equals([AppStatus.authenticated]),
    );
  });

  test('AppEvent props: RefreshCurrentUser has no props', () {
    expect(RefreshCurrentUser().props, isEmpty);
  });

  test('AppEvent props: UpdateFootballFeature exposes bool', () {
    expect(UpdateFootballFeature(true).props, equals([true]));
    expect(UpdateFootballFeature(false).props, equals([false]));
  });

  test('keeps and clears currentUser through AppState.copyWith branches', () {
    final baselineUser = GNUser(
      id: 'user-1',
      displayName: 'Tai',
      phoneNumber: null,
      email: 'tai@example.com',
      photoUrl: null,
      role: 'user',
      fcmToken: '',
    );
    final replacementUser = GNUser(
      id: 'user-2',
      displayName: 'Linh',
      phoneNumber: null,
      email: 'linh@example.com',
      photoUrl: null,
      role: 'user',
      fcmToken: '',
    );
    final state = AppState(
      status: AppStatus.authenticated,
      enableFootballFeature: false,
      currentUser: baselineUser,
    );

    expect(state.copyWith().currentUser, same(baselineUser));
    expect(
      state.copyWith(currentUser: replacementUser).currentUser,
      same(replacementUser),
    );
    expect(
      state.copyWith(enableFootballFeature: true).enableFootballFeature,
      isTrue,
    );
    expect(state.copyWith(clearCurrentUser: true).currentUser, isNull);
    expect(
      state
          .copyWith(currentUser: replacementUser, clearCurrentUser: true)
          .currentUser,
      isNull,
    );
  });

  test('exposes AppStatusX helper getters', () {
    expect(AppStatus.authenticated.isAuthenticated, isTrue);
    expect(AppStatus.unauthenticated.isAuthenticated, isFalse);
    expect(AppStatus.profileIncomplete.isInitializing, isFalse);
    expect(AppStatus.initializing.isInitializing, isTrue);
  });

  test(
    'clears authenticated state when firestore load fails after initial success',
    () async {
      final flakyFirestore = _FlakyFirestore(FakeFirebaseFirestore());
      final bloc = await buildBloc(firestoreOverride: flakyFirestore);

      authController!.add(_firebaseUser(uid: 'user-fail', displayName: 'Tai'));
      await Future<void>.delayed(Duration(milliseconds: 1));
      expect(bloc.state.status, AppStatus.authenticated);
      expect(bloc.state.currentUser?.id, 'user-fail');

      authController!.add(_firebaseUser(uid: 'user-fail', displayName: 'Tai'));
      await Future<void>.delayed(Duration(milliseconds: 1));
      expect(bloc.state.status, AppStatus.unauthenticated);
      expect(bloc.state.currentUser, isNull);
    },
  );
}
