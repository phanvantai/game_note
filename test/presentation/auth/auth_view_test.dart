import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/constants/assets_path.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/auth/auth_view.dart';
import 'package:pes_arena/presentation/auth/sign_in/bloc/sign_in_bloc.dart';
import 'package:pes_arena/presentation/auth/third_party/bloc/third_party_bloc.dart';

class _MockGNAuth extends Mock implements GNAuth {}

class _MockThirdPartyBloc extends MockBloc<ThirdPartyEvent, ThirdPartyState>
    implements ThirdPartyBloc {}

Widget _buildAuthView() {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const Scaffold(body: AuthView()),
  );
}

Finder _appIcon() => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == AssetsPath.appIcon,
);

Finder _emailField() => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == 'Email',
);

Finder _passwordField() => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == 'Password',
);

void main() {
  late _MockGNAuth auth;
  late _MockThirdPartyBloc thirdPartyBloc;

  setUp(() async {
    await getIt.reset();
    auth = _MockGNAuth();
    thirdPartyBloc = _MockThirdPartyBloc();

    when(() => thirdPartyBloc.state).thenReturn(const ThirdPartyState());
    whenListen(
      thirdPartyBloc,
      const Stream<ThirdPartyState>.empty(),
      initialState: const ThirdPartyState(),
    );

    getIt.registerSingleton<ThirdPartyBloc>(thirdPartyBloc);
    getIt.registerFactory<SignInBloc>(() => SignInBloc(auth: auth));
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'renders compact auth wrapper with email/password and google sign in',
    (tester) async {
      await tester.pumpWidget(_buildAuthView());
      await tester.pump();

      expect(_appIcon(), findsOneWidget);
      expect(find.text('PES Arena'), findsNothing);
      expect(find.text('Sign in to continue'), findsNothing);
      expect(find.text('Đăng nhập để tiếp tục'), findsNothing);

      expect(_emailField(), findsOneWidget);
      expect(_passwordField(), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
      expect(find.text('Or'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      expect(find.byIcon(Icons.wifi_off_outlined), findsNothing);
      expect(find.text('Offline'), findsNothing);
    },
  );
}
