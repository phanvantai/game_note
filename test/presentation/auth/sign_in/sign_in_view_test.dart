import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/auth/sign_in/bloc/sign_in_bloc.dart';
import 'package:pes_arena/presentation/auth/sign_in/sign_in_view.dart';

class _MockSignInBloc extends MockBloc<SignInEvent, SignInState>
    implements SignInBloc {}

class _MockGNAuth extends Mock implements GNAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

Widget _buildSignInView({required SignInBloc bloc}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: BlocProvider<SignInBloc>.value(
        value: bloc,
        child: const SignInView(),
      ),
    ),
  );
}

Finder _emailField() => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == 'Email',
);

Finder _passwordField() => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == 'Password',
);

void main() {
  setUp(() {
    setShowToastImpl((_, {gravity = ToastGravity.BOTTOM}) {});
  });

  tearDown(() {
    resetShowToast();
  });

  testWidgets('renders default sign-in mode fields and actions', (
    tester,
  ) async {
    final bloc = SignInBloc(auth: _MockGNAuth());
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildSignInView(bloc: bloc));

    expect(find.byType(SegmentedButton<AuthFormMode>), findsNothing);
    expect(find.text('Sign in'), findsAtLeast(1));
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(_emailField(), findsOneWidget);
    expect(_passwordField(), findsOneWidget);
  });

  testWidgets('typing email/password updates SignInBloc state fields', (
    tester,
  ) async {
    final bloc = SignInBloc(auth: _MockGNAuth());
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildSignInView(bloc: bloc));

    await tester.enterText(_emailField(), 'player@example.com');
    await tester.enterText(_passwordField(), 'secret123');
    await tester.pump();

    expect(bloc.state.email, 'player@example.com');
    expect(bloc.state.password, 'secret123');
  });

  testWidgets('toggling password suffix changes obscure state and icon', (
    tester,
  ) async {
    final bloc = SignInBloc(auth: _MockGNAuth());
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildSignInView(bloc: bloc));
    await tester.enterText(_passwordField(), 'secret123');
    await tester.pump();

    final suffix = find.descendant(
      of: _passwordField(),
      matching: find.byType(IconButton),
    );
    final hiddenIcon = tester.widget<IconButton>(suffix);
    expect((hiddenIcon.icon as Icon).icon, Icons.visibility_off_outlined);

    await tester.tap(suffix);
    await tester.pump();

    final visibleIcon = tester.widget<IconButton>(suffix);
    expect((visibleIcon.icon as Icon).icon, Icons.visibility_outlined);
  });

  testWidgets('register mode keeps password field and updates submit text', (
    tester,
  ) async {
    final bloc = SignInBloc(auth: _MockGNAuth());
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildSignInView(bloc: bloc));

    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Register'), findsOneWidget);
    expect(find.text('Register'), findsNWidgets(2));
    expect(find.text('Already have an account?'), findsOneWidget);
    expect(_passwordField(), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(_passwordField(), findsOneWidget);
  });

  testWidgets(
    'reset-password mode hides password field and updates submit text',
    (tester) async {
      final bloc = SignInBloc(auth: _MockGNAuth());
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildSignInView(bloc: bloc));

      await tester.tap(find.widgetWithText(TextButton, 'Forgot password?'));
      await tester.pump();

      expect(
        find.widgetWithText(FilledButton, 'Send reset email'),
        findsOneWidget,
      );
      expect(find.text('Back to sign in'), findsOneWidget);
      expect(_emailField(), findsOneWidget);
      expect(_passwordField(), findsNothing);
      expect(find.text('Sign in'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Sign in'));
      await tester.pump();

      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(_passwordField(), findsOneWidget);
    },
  );

  testWidgets(
    'loading state disables submit and shows CircularProgressIndicator',
    (tester) async {
      final auth = _MockGNAuth();
      final signInFuture = Completer<UserCredential>();
      when(
        () =>
            auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
      ).thenAnswer((_) => signInFuture.future);

      final bloc = SignInBloc(auth: auth);
      addTearDown(bloc.close);

      await tester.pumpWidget(_buildSignInView(bloc: bloc));

      await tester.enterText(_emailField(), 'player@example.com');
      await tester.enterText(_passwordField(), 'secret123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      signInFuture.complete(_MockUserCredential());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('invalid submit shows email and password errorText in UI', (
    tester,
  ) async {
    final bloc = SignInBloc(auth: _MockGNAuth());
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildSignInView(bloc: bloc));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });

  testWidgets('submit button dispatches AuthFormSubmitted on pressed', (
    tester,
  ) async {
    final bloc = _MockSignInBloc();
    when(() => bloc.state).thenReturn(const SignInState());
    whenListen(
      bloc,
      Stream<SignInState>.empty(),
      initialState: const SignInState(),
    );

    addTearDown(bloc.close);

    await tester.pumpWidget(_buildSignInView(bloc: bloc));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    verify(() => bloc.add(AuthFormSubmitted())).called(1);
  });

  testWidgets('shows success toast when status becomes success', (
    tester,
  ) async {
    String? toastMessage;
    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      toastMessage = message;
    });

    final auth = _MockGNAuth();
    when(
      () => auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
    ).thenAnswer((_) async => _MockUserCredential());
    final bloc = SignInBloc(auth: auth);
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildSignInView(bloc: bloc));
    await tester.enterText(_emailField(), 'player@example.com');
    await tester.enterText(_passwordField(), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(toastMessage, 'Signed in successfully');
  });

  testWidgets('shows error toast when submit fails', (tester) async {
    String? toastMessage;
    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      toastMessage = message;
    });

    final auth = _MockGNAuth();
    when(
      () => auth.signInWithEmailAndPassword('player@example.com', 'secret123'),
    ).thenThrow(FirebaseAuthException(code: 'wrong-password'));
    final bloc = SignInBloc(auth: auth);
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildSignInView(bloc: bloc));
    await tester.enterText(_emailField(), 'player@example.com');
    await tester.enterText(_passwordField(), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(toastMessage, 'Mật khẩu không đúng');
  });

  testWidgets('shows success toast when registering with valid credentials', (
    tester,
  ) async {
    String? toastMessage;
    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      toastMessage = message;
    });

    final auth = _MockGNAuth();
    when(
      () => auth.createUserWithEmailAndPassword(
        'player@example.com',
        'secret123',
      ),
    ).thenAnswer((_) async => _MockUserCredential());
    final bloc = SignInBloc(auth: auth);
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildSignInView(bloc: bloc));
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();

    await tester.enterText(_emailField(), 'player@example.com');
    await tester.enterText(_passwordField(), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pumpAndSettle();

    expect(toastMessage, 'Signed in successfully');
  });

  testWidgets('shows success toast when reset password email is sent', (
    tester,
  ) async {
    String? toastMessage;
    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      toastMessage = message;
    });

    final auth = _MockGNAuth();
    when(
      () => auth.sendPasswordResetEmail('player@example.com'),
    ).thenAnswer((_) async {});
    final bloc = SignInBloc(auth: auth);
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildSignInView(bloc: bloc));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    await tester.enterText(_emailField(), 'player@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
    await tester.pumpAndSettle();

    expect(toastMessage, 'Password reset email sent');
  });
}
