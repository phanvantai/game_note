import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/core/helpers/shared_preferences_helper.dart';
import 'package:pes_arena/core/localization/locale_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LocaleNotifier> buildNotifier({
    Map<String, Object> prefs = const {},
    List<Locale> deviceLocales = const [],
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sharedPreferences = await SharedPreferences.getInstance();
    final helper = SharedPreferencesHelper(sharedPreferences);
    return LocaleNotifier(helper, deviceLocales: deviceLocales);
  }

  test(
    'first launch with Vietnamese device locale preselects Vietnamese',
    () async {
      final notifier = await buildNotifier(
        deviceLocales: const [Locale('vi', 'VN')],
      );

      expect(notifier.initialSelectionFromDevice(), const Locale('vi'));
    },
  );

  test('first launch with English device locale preselects English', () async {
    final notifier = await buildNotifier(
      deviceLocales: const [Locale('en', 'US')],
    );

    expect(notifier.initialSelectionFromDevice(), const Locale('en'));
  });

  test(
    'first launch with unsupported device locale preselects English',
    () async {
      final notifier = await buildNotifier(
        deviceLocales: const [Locale('fr', 'FR')],
      );

      expect(notifier.initialSelectionFromDevice(), const Locale('en'));
    },
  );

  test('saved locale overrides device locale', () async {
    final notifier = await buildNotifier(
      prefs: const {SharedPreferencesHelper.currentLocale: 'vi'},
      deviceLocales: const [Locale('en', 'US')],
    );

    expect(notifier.hasSavedLocale, isTrue);
    expect(notifier.currentLocale, const Locale('vi'));
  });

  test('setLocale persists selected locale', () async {
    final notifier = await buildNotifier(
      deviceLocales: const [Locale('en', 'US')],
    );

    await notifier.setLocale(const Locale('vi'));

    expect(notifier.currentLocale, const Locale('vi'));
    expect(notifier.hasSavedLocale, isTrue);
  });
}
