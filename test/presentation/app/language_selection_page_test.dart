import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/helpers/shared_preferences_helper.dart';
import 'package:pes_arena/core/localization/locale_notifier.dart';
import 'package:pes_arena/core/theme/app_theme.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/app/language_selection_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<Widget> app({
    List<Locale> deviceLocales = const [Locale('vi', 'VN')],
    String initialLocation = '/language',
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = LocaleNotifier(
      SharedPreferencesHelper(prefs),
      deviceLocales: deviceLocales,
    );
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/language',
          builder: (context, state) => LanguageSelectionPage(
            nextLocation: state.uri.queryParameters['next'],
          ),
        ),
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('LOGIN')),
        ),
      ],
    );

    return ChangeNotifierProvider<LocaleNotifier>.value(
      value: notifier,
      child: Consumer<LocaleNotifier>(
        builder: (context, localeNotifier, _) {
          return MaterialApp.router(
            locale: localeNotifier.currentLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }

  testWidgets('renders language options and preselects device language', (
    tester,
  ) async {
    await tester.pumpWidget(await app());
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('selecting language persists and continues to next route', (
    tester,
  ) async {
    await tester.pumpWidget(
      await app(initialLocation: '/language?next=%2Flogin'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SharedPreferencesHelper.currentLocale), 'en');
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('uses app colors in light and dark themes', (tester) async {
    await tester.pumpWidget(await app(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();

    var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppTheme.light.scaffoldBackgroundColor);
    var selectedOption = tester.widget<Container>(
      find.byKey(const ValueKey('language_option_vi')),
    );
    var decoration = selectedOption.decoration! as BoxDecoration;
    expect(
      decoration.border,
      Border.all(color: AppTheme.light.colorScheme.secondary),
    );
    var continueButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('language_continue_button')),
    );
    expect(
      continueButton.style?.backgroundColor?.resolve({}),
      AppTheme.light.colorScheme.secondary,
    );

    await tester.pumpWidget(await app(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppTheme.dark.scaffoldBackgroundColor);
    selectedOption = tester.widget<Container>(
      find.byKey(const ValueKey('language_option_vi')),
    );
    decoration = selectedOption.decoration! as BoxDecoration;
    expect(
      decoration.border,
      Border.all(color: AppTheme.dark.colorScheme.secondary),
    );
    continueButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('language_continue_button')),
    );
    expect(
      continueButton.style?.backgroundColor?.resolve({}),
      AppTheme.dark.colorScheme.secondary,
    );
  });
}
