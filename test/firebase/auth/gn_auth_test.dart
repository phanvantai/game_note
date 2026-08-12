import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/injection_container.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockGNAuth extends Mock implements GNAuth {}

class _MockUser extends Mock implements User {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUserInfo extends Mock implements UserInfo {}

class _FakeAuthCredential extends Fake implements AuthCredential {}

class _FakeAuthProvider extends Fake implements AuthProvider {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAuthCredential());
    registerFallbackValue(_FakeAuthProvider());
  });

  late _MockFirebaseAuth firebaseAuth;
  late _MockUser user;
  late _MockUserCredential userCredential;
  late GNAuth sut;

  setUp(() {
    firebaseAuth = _MockFirebaseAuth();
    user = _MockUser();
    userCredential = _MockUserCredential();
    when(
      () => firebaseAuth.authStateChanges(),
    ).thenAnswer((_) => const Stream.empty());
    sut = GNAuth(auth: firebaseAuth, googleSignInInitialized: () async {});
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<GoogleSignInAuthentication> defaultGoogleAuthenticate() async =>
      const GoogleSignInAuthentication(idToken: 'id-token');

  group('pass-through APIs', () {
    test('auth getter returns injected FirebaseAuth', () {
      expect(sut.auth, same(firebaseAuth));
    });

    test('currentUser delegates to injected FirebaseAuth', () {
      when(() => firebaseAuth.currentUser).thenReturn(user);

      expect(sut.currentUser, same(user));
      verify(() => firebaseAuth.currentUser).called(1);
    });

    test('authStateChanges passes through auth state stream', () async {
      when(
        () => firebaseAuth.authStateChanges(),
      ).thenAnswer((_) => Stream<User?>.fromIterable([user]));

      await expectLater(sut.authStateChanges(), emits(user));
      verify(() => firebaseAuth.authStateChanges()).called(greaterThan(0));
    });

    test(
      'signInWithEmailAndPassword forwards to FirebaseAuth.signInWithEmailAndPassword',
      () async {
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'player@example.com',
            password: 'secret123',
          ),
        ).thenAnswer((_) async => userCredential);

        final result = await sut.signInWithEmailAndPassword(
          'player@example.com',
          'secret123',
        );

        expect(result, same(userCredential));
        verify(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'player@example.com',
            password: 'secret123',
          ),
        ).called(1);
      },
    );

    test(
      'createUserWithEmailAndPassword forwards to FirebaseAuth.createUserWithEmailAndPassword',
      () async {
        when(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'new@example.com',
            password: 'secret123',
          ),
        ).thenAnswer((_) async => userCredential);

        final result = await sut.createUserWithEmailAndPassword(
          'new@example.com',
          'secret123',
        );

        expect(result, same(userCredential));
        verify(
          () => firebaseAuth.createUserWithEmailAndPassword(
            email: 'new@example.com',
            password: 'secret123',
          ),
        ).called(1);
      },
    );

    test(
      'sendPasswordResetEmail forwards to FirebaseAuth.sendPasswordResetEmail',
      () async {
        when(
          () =>
              firebaseAuth.sendPasswordResetEmail(email: 'player@example.com'),
        ).thenAnswer((_) async {});

        await sut.sendPasswordResetEmail('player@example.com');

        verify(
          () =>
              firebaseAuth.sendPasswordResetEmail(email: 'player@example.com'),
        ).called(1);
      },
    );
  });

  test(
    'signInWithApple calls signInWithProvider with AppleAuthProvider',
    () async {
      when(
        () => firebaseAuth.signInWithProvider(
          any(that: isA<AppleAuthProvider>()),
        ),
      ).thenAnswer((_) async => userCredential);

      await sut.signInWithApple();

      verify(
        () => firebaseAuth.signInWithProvider(
          any(that: isA<AppleAuthProvider>()),
        ),
      ).called(1);
    },
  );

  test(
    'signInWithGoogle awaits injected googleSignInInitialized before continuing',
    () async {
      final initGate = Completer<void>();
      final events = <String>[];

      final authWithOrderedGoogleFlow = GNAuth(
        auth: firebaseAuth,
        googleSignInInitialized: () {
          events.add('initialized');
          return initGate.future;
        },
        googleAuthenticate: () async {
          events.add('authenticated');
          return const GoogleSignInAuthentication(idToken: 'id-token');
        },
      );

      when(() => firebaseAuth.signInWithCredential(any())).thenAnswer((
        _,
      ) async {
        events.add('credential');
        return userCredential;
      });

      final signInFuture = authWithOrderedGoogleFlow.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);

      expect(events, ['initialized']);

      initGate.complete();
      await signInFuture;

      expect(events, ['initialized', 'authenticated', 'credential']);
    },
  );

  test(
    'signInWithGoogle rethrows generic exceptions from googleAuthenticate',
    () async {
      final expectedError = Exception('network outage');
      final authWithThrowingGoogleAuthenticate = GNAuth(
        auth: firebaseAuth,
        googleSignInInitialized: () async {},
        googleAuthenticate: () async {
          throw expectedError;
        },
      );

      await expectLater(
        authWithThrowingGoogleAuthenticate.signInWithGoogle(),
        throwsA(same(expectedError)),
      );

      verifyNever(() => firebaseAuth.signInWithCredential(any()));
    },
  );

  test(
    'signInWithGoogle rethrows when GoogleSignInAuthentication.idToken is null',
    () async {
      final authWithNullIdToken = GNAuth(
        auth: firebaseAuth,
        googleSignInInitialized: () async {},
        googleAuthenticate: () async =>
            const GoogleSignInAuthentication(idToken: null),
      );

      await expectLater(
        authWithNullIdToken.signInWithGoogle(),
        throwsA(isA<AssertionError>()),
      );

      verifyNever(() => firebaseAuth.signInWithCredential(any()));
    },
  );

  test(
    'checkLoginMethod true when providerData contains password provider',
    () {
      final passwordInfo = _MockUserInfo();
      final googleInfo = _MockUserInfo();

      when(() => passwordInfo.providerId).thenReturn('password');
      when(() => googleInfo.providerId).thenReturn('google.com');
      when(() => firebaseAuth.currentUser).thenReturn(user);
      when(() => user.providerData).thenReturn([passwordInfo, googleInfo]);

      sut.checkLoginMethod();

      expect(sut.isSignInWithEmailAndPassword, isTrue);
    },
  );

  test('checkLoginMethod false when password provider is absent', () {
    final googleInfo = _MockUserInfo();
    final facebookInfo = _MockUserInfo();

    when(() => googleInfo.providerId).thenReturn('google.com');
    when(() => facebookInfo.providerId).thenReturn('facebook.com');
    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => user.providerData).thenReturn([googleInfo, facebookInfo]);

    sut.checkLoginMethod();

    expect(sut.isSignInWithEmailAndPassword, isFalse);
  });

  test(
    'changePassword reauthenticates with EmailAuthProvider credential and updates password',
    () async {
      final mockUser = _MockUser();
      AuthCredential? passedCredential;

      when(() => firebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('player@example.com');
      when(() => mockUser.reauthenticateWithCredential(any())).thenAnswer((
        invocation,
      ) {
        passedCredential =
            invocation.positionalArguments.single as AuthCredential;
        return Future.value(userCredential);
      });
      when(() => mockUser.updatePassword(any())).thenAnswer((_) async {});

      await sut.changePassword('old-pass', 'new-pass');

      expect(passedCredential?.providerId, 'password');
      expect(passedCredential?.signInMethod, 'password');
      verify(() => mockUser.reauthenticateWithCredential(any())).called(1);
      verify(() => mockUser.updatePassword('new-pass')).called(1);
    },
  );

  test('changePassword no-ops when currentUser is null', () async {
    when(() => firebaseAuth.currentUser).thenReturn(null);

    await sut.changePassword('old-pass', 'new-pass');

    verifyNever(() => user.reauthenticateWithCredential(any()));
    verifyNever(() => user.updatePassword(any()));
  });

  test(
    'changePassword rethrows FirebaseAuthException from reauthentication',
    () async {
      final mockUser = _MockUser();
      when(() => firebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('player@example.com');
      when(() => mockUser.reauthenticateWithCredential(any())).thenThrow(
        FirebaseAuthException(
          code: 'wrong-password',
          message: 'Wrong password',
        ),
      );

      await expectLater(
        sut.changePassword('wrong', 'new-pass'),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'wrong-password',
          ),
        ),
      );

      verify(() => mockUser.reauthenticateWithCredential(any())).called(1);
      verifyNever(() => mockUser.updatePassword(any()));
    },
  );

  test(
    'changePassword rethrows generic errors from reauthentication',
    () async {
      final mockUser = _MockUser();
      when(() => firebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.email).thenReturn('player@example.com');
      when(
        () => mockUser.reauthenticateWithCredential(any()),
      ).thenThrow(Exception('network down'));

      await expectLater(
        sut.changePassword('old', 'new'),
        throwsA(isA<Exception>()),
      );

      verify(() => mockUser.reauthenticateWithCredential(any())).called(1);
      verifyNever(() => mockUser.updatePassword(any()));
    },
  );

  test(
    'signOut calls FirebaseAuth without reading or mutating legacy fcmToken data',
    () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final legacyUser = _MockUser();
      final registeredAuth = _MockGNAuth();

      when(() => registeredAuth.currentUser).thenReturn(legacyUser);
      when(() => legacyUser.uid).thenReturn('u-1');

      getIt.registerSingleton<GNAuth>(registeredAuth);
      getIt.registerSingleton<GNFirestore>(GNFirestore(fakeFirestore));

      await fakeFirestore.collection('users').doc('u-1').set({
        'fcmToken': 'legacy-token',
      });

      when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

      await sut.signOut();

      final userDoc = await fakeFirestore.collection('users').doc('u-1').get();

      expect(userDoc.data()?['fcmToken'], 'legacy-token');
      verify(() => firebaseAuth.signOut()).called(1);
      verifyNever(
        () => firebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    },
  );

  group('Google sign-in normalization', () {
    test(
      'GoogleSignInException with empty description maps to ERROR_ABORTED_BY_USER',
      () async {
        final authWithCanceledGoogle = GNAuth(
          auth: firebaseAuth,
          googleSignInInitialized: () async {},
          googleAuthenticate: () async => throw const GoogleSignInException(
            code: GoogleSignInExceptionCode.canceled,
            description: '',
          ),
        );

        expect(
          () => authWithCanceledGoogle.signInWithGoogle(),
          throwsA(
            isA<FirebaseAuthException>().having(
              (error) => error.code,
              'code',
              'ERROR_ABORTED_BY_USER',
            ),
          ),
        );

        verifyNever(() => firebaseAuth.signInWithCredential(any()));
      },
    );

    test(
      'GoogleSignInException with non-empty description is rethrown',
      () async {
        final exception = GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'Credential Manager not configured',
        );
        final authWithCanceledGoogle = GNAuth(
          auth: firebaseAuth,
          googleSignInInitialized: () async {},
          googleAuthenticate: () async => throw exception,
        );

        await expectLater(
          authWithCanceledGoogle.signInWithGoogle(),
          throwsA(same(exception)),
        );

        verifyNever(() => firebaseAuth.signInWithCredential(any()));
      },
    );

    test(
      'FirebaseAuth popup/closed user exceptions normalize to ERROR_ABORTED_BY_USER',
      () async {
        for (final code in const [
          'popup-closed-by-user',
          'cancelled-popup-request',
        ]) {
          clearInteractions(firebaseAuth);
          when(
            () => firebaseAuth.signInWithCredential(any()),
          ).thenThrow(FirebaseAuthException(code: code));

          final authWithPopupFailure = GNAuth(
            auth: firebaseAuth,
            googleSignInInitialized: () async {},
            googleAuthenticate: defaultGoogleAuthenticate,
          );

          await expectLater(
            authWithPopupFailure.signInWithGoogle(),
            throwsA(
              isA<FirebaseAuthException>().having(
                (error) => error.code,
                'code',
                'ERROR_ABORTED_BY_USER',
              ),
            ),
          );
        }
      },
    );

    test(
      'successful injected Google token path signs in with provider credential',
      () async {
        final authWithGoogleAuth = GNAuth(
          auth: firebaseAuth,
          googleSignInInitialized: () async {},
          googleAuthenticate: defaultGoogleAuthenticate,
        );
        AuthCredential? passedCredential;

        when(() => firebaseAuth.signInWithCredential(any())).thenAnswer((
          invocation,
        ) {
          passedCredential =
              invocation.positionalArguments.single as AuthCredential;
          return Future.value(userCredential);
        });

        await authWithGoogleAuth.signInWithGoogle();

        expect(passedCredential, isNotNull);
        expect(passedCredential?.providerId, 'google.com');
        verify(() => firebaseAuth.signInWithCredential(any())).called(1);
      },
    );
  });

  group('Google sign-in seams', () {
    test(
      'GNAuth can be forced to web behavior for tests and uses signInWithPopup',
      () async {
        final authInWebModeForTest = GNAuth(
          auth: firebaseAuth,
          isWebForTesting: true,
        );

        when(
          () => firebaseAuth.signInWithPopup(any()),
        ).thenAnswer((_) async => userCredential);

        final result = await authInWebModeForTest.signInWithGoogle();

        expect(result, same(userCredential));
        verify(
          () => firebaseAuth.signInWithPopup(
            any(that: isA<GoogleAuthProvider>()),
          ),
        ).called(1);
      },
    );

    test(
      'default native flow can use injected googleAuthenticate callback without initializer',
      () async {
        var authenticateCalled = false;
        AuthCredential? capturedCredential;
        final authWithDefaultNativeCallback = GNAuth(
          auth: firebaseAuth,
          googleAuthenticate: () async {
            authenticateCalled = true;
            return const GoogleSignInAuthentication(idToken: 'id-token');
          },
        );

        when(() => firebaseAuth.signInWithCredential(any())).thenAnswer((
          invocation,
        ) {
          capturedCredential =
              invocation.positionalArguments.single as AuthCredential;
          return Future.value(userCredential);
        });

        await authWithDefaultNativeCallback.signInWithGoogle();

        expect(authenticateCalled, isTrue);
        expect(capturedCredential?.providerId, 'google.com');
        expect(capturedCredential?.signInMethod, 'google.com');
        verify(() => firebaseAuth.signInWithCredential(any())).called(1);
        verifyNever(() => firebaseAuth.signInWithPopup(any()));
      },
    );

    test(
      'googleSignInInitializer is invoked for native flow and skipped for web-for-testing',
      () async {
        final initOrder = <String>[];

        final nativeAuth = GNAuth(
          auth: firebaseAuth,
          googleAuthenticate: defaultGoogleAuthenticate,
          googleSignInInitializer: () async {
            initOrder.add('initialized');
          },
        );

        when(() => firebaseAuth.signInWithCredential(any())).thenAnswer((
          invocation,
        ) {
          initOrder.add('credential');
          return Future.value(userCredential);
        });

        await nativeAuth.signInWithGoogle();

        expect(initOrder, equals(['initialized', 'credential']));

        final webAuth = GNAuth(
          auth: firebaseAuth,
          isWebForTesting: true,
          googleAuthenticate: defaultGoogleAuthenticate,
          googleSignInInitializer: () async {
            initOrder.add('web-initialized');
          },
        );

        when(
          () => firebaseAuth.signInWithPopup(any()),
        ).thenAnswer((_) async => userCredential);
        initOrder.clear();

        await webAuth.signInWithGoogle();

        expect(initOrder, isNot(contains('web-initialized')));
      },
    );
  });
}
