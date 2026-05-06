import 'package:shared_preferences/shared_preferences.dart';

/// Per-device preferences for the head-to-head section. Currently just the
/// minimum-matches threshold used to filter opponents — kept here so the
/// UI can show / edit it without coupling the widget to SharedPreferences
/// directly.
class H2HPreferences {
  final SharedPreferences _prefs;

  H2HPreferences(this._prefs);

  static const String _minMatchesKey = 'dashboard.h2h.min_matches';

  /// Default if the user has never set one. Tuned for hardcore players
  /// who easily rack up hundreds of matches — 20 turned out to be too low
  /// (variance dominated the leaderboard).
  static const int defaultMinMatches = 50;

  /// Hard bounds for the slider. 1 = "show me anything"; 200 caps the
  /// slider so heavy users with thousands of matches still see something.
  static const int minBound = 1;
  static const int maxBound = 200;

  int get minMatches {
    final stored = _prefs.getInt(_minMatchesKey);
    if (stored == null) return defaultMinMatches;
    return stored.clamp(minBound, maxBound);
  }

  Future<void> setMinMatches(int value) async {
    final clamped = value.clamp(minBound, maxBound);
    await _prefs.setInt(_minMatchesKey, clamped);
  }
}
