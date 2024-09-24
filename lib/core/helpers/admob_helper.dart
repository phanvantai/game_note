import 'dart:io';

import 'package:flutter/foundation.dart';

class AdmobHelper {
  static String get bannerUnitIDHomeBottom {
    final isIOS = Platform.isIOS;
    if (kDebugMode) {
      return isIOS ? testBannerIdIOS : testBannerIdAndroid;
    } else {
      return isIOS ? bannerIdIOSHomeBottom : bannerIdAndroidHomeBottom;
    }
  }

  static String get bannerUnitIDDetailBottom {
    final isIOS = Platform.isIOS;
    if (kDebugMode) {
      return isIOS ? testBannerIdIOS : testBannerIdAndroid;
    } else {
      return isIOS ? bannerIdIOSDetailBottom : bannerIdAndroidDetailBottom;
    }
  }

  static const String testBannerIdIOS =
      'ca-app-pub-3940256099942544/2934735716';
  static const String testBannerIdAndroid =
      'ca-app-pub-3940256099942544/6300978111';

  static const String bannerIdIOSHomeBottom =
      'ca-app-pub-8555407335287438/5561408974';
  static const String bannerIdIOSDetailBottom =
      'ca-app-pub-8555407335287438/5146476009';
  static const String bannerIdAndroidHomeBottom =
      'ca-app-pub-8555407335287438/7786550395';
  static const String bannerIdAndroidDetailBottom =
      'ca-app-pub-8555407335287438/2520312661';
}
