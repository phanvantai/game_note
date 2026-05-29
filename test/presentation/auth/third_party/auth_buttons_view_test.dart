import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/auth/third_party/auth_buttons_view.dart';
import 'package:pes_arena/presentation/auth/third_party/bloc/third_party_bloc.dart';

class _MockThirdPartyBloc extends MockBloc<ThirdPartyEvent, ThirdPartyState>
    implements ThirdPartyBloc {}

const _kErrorMessage = 'Could not sign in with Google';

Widget _buildAuthButtonsView({ThemeData? theme}) {
  return MaterialApp(
    locale: const Locale('en'),
    theme: theme ?? ThemeData.light(),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const Scaffold(body: AuthButtonsView()),
  );
}

void main() {
  late _MockThirdPartyBloc bloc;

  setUpAll(() {
    registerFallbackValue(const ThirdPartySignInGoogle());
    registerFallbackValue(const ThirdPartySignInApple());
  });

  setUp(() async {
    await getIt.reset();
    bloc = _MockThirdPartyBloc();
    getIt.registerSingleton<ThirdPartyBloc>(bloc);
    debugDefaultTargetPlatformOverride = null;
    when(() => bloc.state).thenReturn(const ThirdPartyState());
    whenListen(
      bloc,
      const Stream<ThirdPartyState>.empty(),
      initialState: const ThirdPartyState(),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('AuthButtonsView', () {
    testWidgets('shows idle Google button text', (tester) async {
      await tester.pumpWidget(_buildAuthButtonsView());
      await tester.pump();

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton).first,
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows loading indicator and disables Google button', (
      tester,
    ) async {
      const loadingState = ThirdPartyState(status: ViewStatus.loading);
      when(() => bloc.state).thenReturn(loadingState);
      whenListen(
        bloc,
        const Stream<ThirdPartyState>.empty(),
        initialState: loadingState,
      );

      await tester.pumpWidget(_buildAuthButtonsView());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);
      final button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton).first,
      );
      expect(button.onPressed, isNull);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      verifyNever(() => bloc.add(any(that: isA<ThirdPartySignInGoogle>())));
    });

    testWidgets('covers dark theme button branch', (tester) async {
      when(() => bloc.state).thenReturn(const ThirdPartyState());
      whenListen(
        bloc,
        const Stream<ThirdPartyState>.empty(),
        initialState: const ThirdPartyState(),
      );

      await tester.pumpWidget(_buildAuthButtonsView(theme: ThemeData.dark()));
      await tester.pump();

      final button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton).first,
      );
      expect(button.style, isNotNull);
      expect(button.onPressed, isNotNull);
    });

    testWidgets(
      'dispatches Google sign-in event when Google button is tapped',
      (tester) async {
        when(() => bloc.state).thenReturn(const ThirdPartyState());
        whenListen(
          bloc,
          const Stream<ThirdPartyState>.empty(),
          initialState: const ThirdPartyState(),
        );

        await tester.pumpWidget(_buildAuthButtonsView());
        await tester.pump();

        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();

        verify(() => bloc.add(const ThirdPartySignInGoogle())).called(1);
      },
    );

    testWidgets('shows failure snackbar on failure state', (tester) async {
      when(() => bloc.state).thenReturn(const ThirdPartyState());
      whenListen(
        bloc,
        Stream<ThirdPartyState>.fromIterable([
          const ThirdPartyState(
            status: ViewStatus.failure,
            error: _kErrorMessage,
          ),
        ]),
        initialState: const ThirdPartyState(),
      );

      await tester.pumpWidget(_buildAuthButtonsView());
      await tester.pumpAndSettle();

      expect(find.text(_kErrorMessage), findsOneWidget);
    });

    testWidgets('shows success snackbar on success state', (tester) async {
      when(() => bloc.state).thenReturn(const ThirdPartyState());
      whenListen(
        bloc,
        Stream<ThirdPartyState>.fromIterable([
          const ThirdPartyState(status: ViewStatus.success),
        ]),
        initialState: const ThirdPartyState(),
      );

      await tester.pumpWidget(_buildAuthButtonsView());
      await tester.pumpAndSettle();

      expect(find.text('Signed in successfully'), findsOneWidget);
    });

    testWidgets('shows Apple button and dispatches Apple event on iOS', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
      });

      try {
        when(() => bloc.state).thenReturn(const ThirdPartyState());
        whenListen(
          bloc,
          const Stream<ThirdPartyState>.empty(),
          initialState: const ThirdPartyState(),
        );

        await tester.pumpWidget(_buildAuthButtonsView());
        await tester.pump();

        expect(find.text('Continue with Apple'), findsOneWidget);

        await tester.tap(find.text('Continue with Apple'));
        await tester.pump();

        verify(() => bloc.add(const ThirdPartySignInApple())).called(1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
