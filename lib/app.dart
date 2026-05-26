import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'core/localization/locale_notifier.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/web_shell/web_shell.dart';
import 'routing.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return Consumer<LocaleNotifier>(
          builder: (context, localeNotifier, _) {
            if (kDebugMode) {
              debugPrint(
                '[BootFlow] App.build: '
                'locale=${localeNotifier.currentLocale?.languageCode} '
                'hasSavedLocale=${localeNotifier.hasSavedLocale} '
                'themeMode=${themeNotifier.themeMode}',
              );
            }
            return MaterialApp.router(
              routerConfig: appRouter,
              debugShowCheckedModeBanner: false,
              locale: localeNotifier.currentLocale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              localeResolutionCallback: (locale, supportedLocales) =>
                  LocaleNotifier.resolve(locale, supportedLocales),
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeNotifier.themeMode,
              builder: (context, child) =>
                  WebShell(child: child ?? const SizedBox.shrink()),
            );
          },
        );
      },
    );
  }
}
