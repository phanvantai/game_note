import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  // key
  static const String authToken = "auth_token";
  static const String refreshToken = 'refresh_token';
  static const String currentLocale = "current_locale";
  static const String currentUser = "current_user";
  static const String usageTime = "usage_time";
  static const String lastPostUsageTime = "last_post_usage_time";
  static const String lastUpdatedAccessToken = 'last_updated_access_token';
  static const String fcmToken = 'fcm_token';

  static const String communityMode = 'community_mode';

  // shared pref instance
  final SharedPreferences _sharedPreferences;

  // constructor
  SharedPreferencesHelper(this._sharedPreferences);

  bool? get isCommunityMode {
    return _sharedPreferences.getBool(SharedPreferencesHelper.communityMode);
  }

  setCommunityMode(bool value) {
    return _sharedPreferences.setBool(
        SharedPreferencesHelper.communityMode, value);
  }

  String get getLastPostUsageTime {
    return _sharedPreferences
            .getString(SharedPreferencesHelper.lastPostUsageTime) ??
        '';
  }

  Future<bool> setLastPostUsageTime(String last) {
    return _sharedPreferences.setString(
        SharedPreferencesHelper.lastPostUsageTime, last);
  }

  // current locale code
  String get getCurrentLocale {
    return _sharedPreferences
            .getString(SharedPreferencesHelper.currentLocale) ??
        '';
  }

  Future<void> setCurrentLocale(String currentLocale) {
    return _sharedPreferences.setString(
        SharedPreferencesHelper.currentLocale, currentLocale);
  }

  DateTime? get getLastUpdatedAccessToken {
    var dateString = _sharedPreferences
        .getString(SharedPreferencesHelper.lastUpdatedAccessToken);
    return dateString == null ? null : DateTime.parse(dateString);
  }

  Future<bool> setLastUpdatedAccessToken(DateTime dateTime) {
    return _sharedPreferences.setString(
        SharedPreferencesHelper.lastUpdatedAccessToken,
        dateTime.toIso8601String());
  }

  // fcm token
  String get getFcmToken {
    return _sharedPreferences.getString(SharedPreferencesHelper.fcmToken) ?? '';
  }

  Future<bool> setFcmToken(String fcmToken) {
    return _sharedPreferences.setString(
        SharedPreferencesHelper.fcmToken, fcmToken);
  }

  // token
  String get getAuthToken {
    return _sharedPreferences.getString(SharedPreferencesHelper.authToken) ??
        '';
  }

  Future<bool> setAuthToken(String authToken) {
    return _sharedPreferences.setString(
        SharedPreferencesHelper.authToken, authToken);
  }

  // refresh token
  String get getRefreshToken {
    return _sharedPreferences.getString(SharedPreferencesHelper.refreshToken) ??
        '';
  }

  Future<void> setRefreshToken(String refreshToken) {
    return _sharedPreferences.setString(
        SharedPreferencesHelper.refreshToken, refreshToken);
  }
}
