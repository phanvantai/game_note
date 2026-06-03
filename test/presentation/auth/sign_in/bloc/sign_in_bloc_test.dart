import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/presentation/auth/sign_in/bloc/sign_in_bloc.dart';

class _MockGNAuth extends Mock implements GNAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

void main() {
  late _MockGNAuth auth;
  late UserCredential credential;

  setUp(() {
    auth = _MockGNAuth();
    credential = _MockUserCredential();
  });

  SignInBloc buildBloc() => SignInBloc(auth: auth);

  test(
    'sign-in mode signs in existing user without creating account',
    () async {
      when(
        () =>
            auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
      ).thenAnswer((_) async => credential);

      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(EmailChanged('player@example.com'));
      bloc.add(PasswordChanged('secret123'));
      bloc.add(AuthFormSubmitted());
      await Future<void>.delayed(Duration.zero);

      verify(
        () =>
            auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
      ).called(1);
      verifyNever(() => auth.createUserWithEmailAndPassword(any(), any()));
      expect(bloc.state.status, SignInStatus.success);
    },
  );

  test('default constructor uses getIt-registered GNAuth when no auth is provided', () async {
    when(
      () =>
          auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
    ).thenAnswer((_) async => credential);

    if (getIt.isRegistered<GNAuth>()) {
      getIt.unregister<GNAuth>();
    }
    getIt.registerSingleton<GNAuth>(auth);
    addTearDown(() {
      if (getIt.isRegistered<GNAuth>()) {
        getIt.unregister<GNAuth>();
      }
    });

    final bloc = SignInBloc();
    addTearDown(bloc.close);

    bloc.add(EmailChanged('player@example.com'));
    bloc.add(PasswordChanged('secret123'));
    bloc.add(AuthFormSubmitted());
    await Future<void>.delayed(Duration.zero);

    verify(
      () =>
          auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
    ).called(1);
    expect(bloc.state.status, SignInStatus.success);
  });

  test('EmailSignInSubmitted forwards to AuthFormSubmitted', () async {
    when(
      () =>
          auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
    ).thenAnswer((_) async => credential);

    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(EmailChanged('player@example.com'));
    bloc.add(PasswordChanged('secret123'));
    bloc.add(EmailSignInSubmitted());
    await Future<void>.delayed(Duration.zero);

    verify(
      () =>
          auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
    ).called(1);
    expect(bloc.state.status, SignInStatus.success);
  });

  test('invalidates submission when email is empty', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(EmailChanged(''));
    bloc.add(PasswordChanged('secret123'));
    bloc.add(AuthFormSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, SignInStatus.invalid);
    expect(bloc.state.emailError, 'Vui lòng nhập email');
    verifyNever(() => auth.signInWithEmailAndPassword(any(), any()));
  });

  test('invalidates submission when email format is invalid', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(EmailChanged('bad-email'));
    bloc.add(PasswordChanged('secret123'));
    bloc.add(AuthFormSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, SignInStatus.invalid);
    expect(bloc.state.emailError, 'Vui lòng nhập email hợp lệ');
    verifyNever(() => auth.signInWithEmailAndPassword(any(), any()));
  });

  test('invalidates submission when password is empty', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(EmailChanged('player@example.com'));
    bloc.add(PasswordChanged(''));
    bloc.add(AuthFormSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, SignInStatus.invalid);
    expect(bloc.state.passwordError, 'Vui lòng nhập mật khẩu');
    verifyNever(() => auth.signInWithEmailAndPassword(any(), any()));
  });

  test('invalidates submission when password is too short', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(EmailChanged('player@example.com'));
    bloc.add(PasswordChanged('12345'));
    bloc.add(AuthFormSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, SignInStatus.invalid);
    expect(
      bloc.state.passwordError,
      'Mật khẩu phải có ít nhất 6 ký tự',
    );
    verifyNever(() => auth.signInWithEmailAndPassword(any(), any()));
  });

  test(
    'register mode creates account without trying sign-in fallback',
    () async {
      when(
        () => auth.createUserWithEmailAndPassword(
          'player@example.com',
          'secret123',
        ),
      ).thenAnswer((_) async => credential);

      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(AuthFormModeChanged(AuthFormMode.register));
      bloc.add(EmailChanged('player@example.com'));
      bloc.add(PasswordChanged('secret123'));
      bloc.add(AuthFormSubmitted());
      await Future<void>.delayed(Duration.zero);

      verify(
        () => auth.createUserWithEmailAndPassword(
          'player@example.com',
          'secret123',
        ),
      ).called(1);
      verifyNever(() => auth.signInWithEmailAndPassword(any(), any()));
      expect(bloc.state.status, SignInStatus.success);
    },
  );

  test('reset password mode sends password reset email', () async {
    when(
      () => auth.sendPasswordResetEmail('player@example.com'),
    ).thenAnswer((_) async {});

    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(AuthFormModeChanged(AuthFormMode.resetPassword));
    bloc.add(EmailChanged('player@example.com'));
    bloc.add(AuthFormSubmitted());
    await Future<void>.delayed(Duration.zero);

    verify(() => auth.sendPasswordResetEmail('player@example.com')).called(1);
    verifyNever(() => auth.signInWithEmailAndPassword(any(), any()));
    verifyNever(() => auth.createUserWithEmailAndPassword(any(), any()));
    expect(bloc.state.status, SignInStatus.success);
  });

  test('maps wrong password Firebase error to user-facing message', () async {
    when(
      () => auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
    ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(EmailChanged('player@example.com'));
    bloc.add(PasswordChanged('secret123'));
    bloc.add(AuthFormSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, SignInStatus.error);
    expect(bloc.state.error, 'Mật khẩu không đúng');
  });

  final firebaseErrorMappings = {
    'too-many-requests': 'Quá nhiều yêu cầu, vui lòng thử lại sau',
    'user-not-found': 'Email không tồn tại',
    'email-already-in-use': 'Email đã được sử dụng',
    'invalid-email': 'Email không hợp lệ',
    'weak-password': 'Mật khẩu phải có ít nhất 6 ký tự',
  };

  for (final entry in firebaseErrorMappings.entries) {
    test(
      'maps ${entry.key} Firebase error to user-facing message',
      () async {
        when(
          () =>
              auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
        ).thenThrow(FirebaseAuthException(code: entry.key));

        final bloc = buildBloc();
        addTearDown(bloc.close);

        bloc.add(EmailChanged('player@example.com'));
        bloc.add(PasswordChanged('secret123'));
        bloc.add(AuthFormSubmitted());
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.status, SignInStatus.error);
        expect(bloc.state.error, entry.value);
      },
    );
  }

  test('maps unknown Firebase error to default message', () async {
    when(
      () => auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
    ).thenThrow(FirebaseAuthException(code: 'unknown-error'));

    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(EmailChanged('player@example.com'));
    bloc.add(PasswordChanged('secret123'));
    bloc.add(AuthFormSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, SignInStatus.error);
    expect(bloc.state.error, 'Đã có lỗi xảy ra');
  });

  test('maps non-Firebase exceptions to exception toString message', () async {
    when(
      () =>
          auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
    ).thenThrow(Exception('network down'));

    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(EmailChanged('player@example.com'));
    bloc.add(PasswordChanged('secret123'));
    bloc.add(AuthFormSubmitted());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, SignInStatus.error);
    expect(bloc.state.error, 'Exception: network down');
  });

  group('SignInEvent props', () {
    test('AuthFormModeChanged includes mode in props', () {
      expect(AuthFormModeChanged(AuthFormMode.register).props, [
        AuthFormMode.register,
      ]);
    });

    test('EmailChanged includes email in props', () {
      expect(EmailChanged('x@y.com').props, ['x@y.com']);
    });

    test('PasswordChanged includes password in props', () {
      expect(PasswordChanged('secret').props, ['secret']);
    });

    test('AuthFormSubmitted has empty props', () {
      expect(AuthFormSubmitted().props, isEmpty);
    });

    test('EmailSignInSubmitted has empty props', () {
      expect(EmailSignInSubmitted().props, isEmpty);
    });
  });

  test('AuthFormModeChanged updates sign-in mode to register', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(AuthFormModeChanged(AuthFormMode.register));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.mode, AuthFormMode.register);
    expect(bloc.state.status, SignInStatus.initial);
  });

  test('EmailChanged updates email in state', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(EmailChanged('x@y.com'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.email, 'x@y.com');
    expect(bloc.state.emailError, '');
  });

  test('PasswordChanged updates password in state', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(PasswordChanged('secret'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.password, 'secret');
    expect(bloc.state.passwordError, '');
  });
}
