import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';

/// Local cache for the group overview summary so opening Tổng quan
/// renders instantly while a fresh fetch happens in the background.
///
/// Keyed per-group so different groups don't collide.
class GroupOverviewCache {
  final SharedPreferences _prefs;

  GroupOverviewCache(this._prefs);

  static const String _keyPrefix = 'group_overview_cache_v1_';

  String _key(String groupId) => '$_keyPrefix$groupId';

  Future<GNEsportGroupStatsSummary?> read(String groupId) async {
    final raw = _prefs.getString(_key(groupId));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GNEsportGroupStatsSummary.fromJson(map);
    } catch (_) {
      // Corrupt entry — drop it and return miss. Cache is best-effort.
      await _prefs.remove(_key(groupId));
      return null;
    }
  }

  Future<void> write(
      String groupId, GNEsportGroupStatsSummary summary) async {
    final encoded = jsonEncode(summary.toJson());
    await _prefs.setString(_key(groupId), encoded);
  }

  Future<void> clear(String groupId) async {
    await _prefs.remove(_key(groupId));
  }
}
