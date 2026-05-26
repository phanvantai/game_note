import 'package:pes_arena/core/localization/locale_notifier.dart';
import 'package:pes_arena/injection_container.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';
import 'generated/app_localizations_vi.dart';

AppLocalizations get appText {
  if (getIt.isRegistered<LocaleNotifier>()) {
    final locale = getIt<LocaleNotifier>().currentLocale;
    if (locale?.languageCode == 'vi') return AppLocalizationsVi();
    return AppLocalizationsEn();
  }
  return AppLocalizationsVi();
}
