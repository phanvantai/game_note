import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/core/helpers/shared_preferences_helper.dart';
import 'package:pes_arena/core/localization/locale_notifier.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:pes_arena/presentation/app/language_selection_page.dart';
import 'package:pes_arena/presentation/app/splash_page.dart';
import 'package:pes_arena/routing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    await getIt.reset();
  });

  tearDown(() => getIt.reset());

  Future<Widget> app({
    required String initialLocation,
    Map<String, Object> prefs = const {},
    AppStatus appStatus = AppStatus.initializing,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sharedPreferences = await SharedPreferences.getInstance();
    final localeNotifier = LocaleNotifier(
      SharedPreferencesHelper(sharedPreferences),
      deviceLocales: const [Locale('vi', 'VN')],
    );
    getIt.registerSingleton<LocaleNotifier>(localeNotifier);
    final appBloc = AppBloc();
    if (appStatus != AppStatus.initializing) {
      appBloc.add(AuthStatusChanged(appStatus));
      await Future<void>.delayed(Duration.zero);
    }
    getIt.registerSingleton<AppBloc>(appBloc);

    return ChangeNotifierProvider<LocaleNotifier>.value(
      value: localeNotifier,
      child: MaterialApp.router(
        locale: localeNotifier.currentLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: createAppRouter(initialLocation: initialLocation),
      ),
    );
  }

  testWidgets('first install redirects login to language selection', (
    tester,
  ) async {
    await tester.pumpWidget(await app(initialLocation: Routing.login));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(LanguageSelectionPage), findsOneWidget);
    expect(find.text('Choose your language'), findsOneWidget);
  });

  testWidgets('saved locale skips language selection', (tester) async {
    await tester.pumpWidget(
      await app(
        initialLocation: Routing.login,
        prefs: const {SharedPreferencesHelper.currentLocale: 'vi'},
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(LanguageSelectionPage), findsNothing);
    expect(find.byType(SplashPage), findsOneWidget);
  });

  testWidgets('first install stale route opens language selection', (
    tester,
  ) async {
    await tester.pumpWidget(await app(initialLocation: '/legacy-route'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(LanguageSelectionPage), findsOneWidget);
    expect(find.text('Page not found'), findsNothing);
  });

  test('stale language next route falls back home instead of 404', () {
    expect(Routing.safeNextLocation('/legacy-route'), Routing.app);
    expect(
      Routing.safeNextLocation('https://example.com/group/g1'),
      Routing.app,
    );
    expect(
      Routing.safeNextLocation('/tournament/league-1'),
      '/tournament/league-1',
    );
  });
}
