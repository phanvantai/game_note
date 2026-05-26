import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../helpers/shared_preferences_helper.dart';

class LocaleNotifier extends ChangeNotifier {
  static const supportedLocales = [Locale('en'), Locale('vi')];
  static const fallbackLocale = Locale('en');

  LocaleNotifier(this._preferences, {List<Locale>? deviceLocales})
    : _deviceLocales = deviceLocales ?? PlatformDispatcher.instance.locales {
    final saved = _preferences.getCurrentLocale;
    if (_isSupportedCode(saved)) {
      _currentLocale = Locale(saved);
    }
    if (kDebugMode) {
      debugPrint(
        '[LocaleFlow] LocaleNotifier.init: '
        'saved="$saved" current=${_currentLocale?.languageCode} '
        'deviceLocales=${_deviceLocales.map((locale) => locale.toLanguageTag()).join(',')}',
      );
    }
  }

  final SharedPreferencesHelper _preferences;
  final List<Locale> _deviceLocales;
  Locale? _currentLocale;

  Locale? get currentLocale => _currentLocale;

  bool get hasSavedLocale => _isSupportedCode(_preferences.getCurrentLocale);

  Locale initialSelectionFromDevice([List<Locale>? locales]) {
    final saved = _preferences.getCurrentLocale;
    if (_isSupportedCode(saved)) {
      if (kDebugMode) {
        debugPrint('[LocaleFlow] initialSelection: saved=$saved');
      }
      return Locale(saved);
    }

    for (final locale in locales ?? _deviceLocales) {
      final code = locale.languageCode.toLowerCase();
      if (_isSupportedCode(code)) {
        if (kDebugMode) {
          debugPrint(
            '[LocaleFlow] initialSelection: device=${locale.toLanguageTag()} -> $code',
          );
        }
        return Locale(code);
      }
    }
    if (kDebugMode) {
      debugPrint(
        '[LocaleFlow] initialSelection: unsupported device locale -> ${fallbackLocale.languageCode}',
      );
    }
    return fallbackLocale;
  }

  Future<void> setLocale(Locale locale) async {
    final languageCode = _isSupportedCode(locale.languageCode)
        ? locale.languageCode
        : fallbackLocale.languageCode;
    _currentLocale = Locale(languageCode);
    await _preferences.setCurrentLocale(languageCode);
    if (kDebugMode) {
      debugPrint('[LocaleFlow] setLocale: saved=$languageCode');
    }
    notifyListeners();
  }

  static Locale resolve(Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) return fallbackLocale;
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) return supported;
    }
    return fallbackLocale;
  }

  static bool _isSupportedCode(String code) {
    return supportedLocales.any((locale) => locale.languageCode == code);
  }
}
