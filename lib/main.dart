import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pes_arena/app.dart';
import 'package:pes_arena/injection_container.dart' as di;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/localization/locale_notifier.dart';
import 'core/theme/theme_provider.dart';
import 'firebase/remote_config/gn_remote_config.dart';
import 'offline/data/database/database_manager.dart';
import 'presentation/app/bloc/app_bloc.dart';
import 'firebase_options.dart';
import 'injection_container.dart';

var dataFile = '';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('[BootFlow] main: WidgetsFlutterBinding ready');
  }
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('[BootFlow] main: Firebase initialized');
  }
  await di.init();
  if (kDebugMode) {
    final localeNotifier = getIt<LocaleNotifier>();
    debugPrint(
      '[BootFlow] main: DI initialized '
      'locale=${localeNotifier.currentLocale?.languageCode} '
      'hasSavedLocale=${localeNotifier.hasSavedLocale}',
    );
  }
  await di.getIt<GNRemoteConfig>().initialize();
  if (kDebugMode) {
    debugPrint('[BootFlow] main: RemoteConfig initialized');
  }
  if (!kIsWeb && di.getIt<GNRemoteConfig>().adsEnabled) {
    MobileAds.instance.initialize();
  }
  if (!kIsWeb) {
    await di.getIt<DatabaseManager>().open();
    if (kDebugMode) {
      debugPrint('[BootFlow] main: offline database opened');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final themeNotifier = ThemeNotifier(prefs);
  if (kDebugMode) {
    debugPrint('[BootFlow] main: runApp');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
        ChangeNotifierProvider<LocaleNotifier>.value(
          value: getIt<LocaleNotifier>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<AppBloc>()..add(InitApp())),
        ],
        child: const App(),
      ),
    ),
  );
}
