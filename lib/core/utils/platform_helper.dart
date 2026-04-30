// lib/core/utils/platform_helper.dart

import 'dart:io';

class PlatformHelper {
  // Check if running on Android
  static bool get isAndroid => Platform.isAndroid;

  // Check if running on iOS
  static bool get isIOS => Platform.isIOS;

  // Get platform name
  static String get platformName => isAndroid ? 'Android' : 'iOS';

  // Get platform-specific store URL
  static String getStoreUrl({
    required String androidPackageName,
    required String iosAppId,
  }) {
    if (isAndroid) {
      return 'https://play.google.com/store/apps/details?id=$androidPackageName';
    } else if (isIOS) {
      return 'https://apps.apple.com/app/id$iosAppId';
    }
    return '';
  }
}
