import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class GNRemoteConfig {
  static const String adsEnabledKey = 'ads_enabled';

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults(const {adsEnabledKey: false});
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('GNRemoteConfig init failed: $e');
    }
  }

  bool get adsEnabled => _remoteConfig.getBool(adsEnabledKey);
}
