//lib/data/models/update_models.dart

import 'dart:io';
import '../../core/network/api_constants.dart';

// Update Configuration and Constants
class UpdateConfig {
  // API Configuration
  static const String baseUrl = ApiConstants.baseUrl;
  static const String versionEndpoint = 'version-info';
  static const int apiTimeoutSeconds = 10;

  // Update Types
  static const String updateTypeForce = 'FORCE';
  static const String updateTypeOptional = 'OPTIONAL';
  static const String updateTypeRecommended = 'RECOMMENDED';

  // Preferences Keys
  static const String prefGracePrefix = 'grace_start_';
  static const String prefDismissedVersion = 'dismissed_version';
  static const String prefLastCheckTime = 'last_update_check';

  // Default Values
  static const int defaultGracePeriod = 7;
  static const int minCheckIntervalHours = 6;

  // iOS App Store ID
  static const String iosAppStoreId = '6747597147';





  // Debug Mode (TURN OFF for production)
  static const bool enableTestingScreen = true; // ⚠️ Set to false before App Store submission





  // Store URLs
  static String getPlayStoreUrl(String packageName) {
    return 'https://play.google.com/store/apps/details?id=$packageName';
  }

  static String getAppStoreUrl(String appId) {
    return 'https://apps.apple.com/app/id$appId';
  }
}

// Platform-specific Version Info
class PlatformVersionInfo {
  final int versionCode;
  final String versionName;
  final int minSupportedVersion;
  final List<int> forceUpdateVersions;
  final String? releaseNotes;

  PlatformVersionInfo({
    required this.versionCode,
    required this.versionName,
    required this.minSupportedVersion,
    required this.forceUpdateVersions,
    this.releaseNotes,
  });

  factory PlatformVersionInfo.fromJson(Map<String, dynamic> json) {
    return PlatformVersionInfo(
      versionCode: json['version_code'] ?? 0,
      versionName: json['version_name'] ?? '',
      minSupportedVersion: json['min_supported_version'] ?? 0,
      forceUpdateVersions:
      List<int>.from(json['force_update_versions'] ?? []),
      releaseNotes: json['release_notes'],
    );
  }
}

/// Version Info Model from API (supports both platforms)
class VersionInfo {
  final PlatformVersionInfo? android;
  final PlatformVersionInfo? ios;
  final PlatformVersionInfo? root;

  final int gracePeriodDays;
  final String updateType;
  final bool killSwitch;
  final String? updateMessage;
  final int? updatePriority;

  VersionInfo({
    this.android,
    this.ios,
    this.root,
    required this.gracePeriodDays,
    required this.updateType,
    this.killSwitch = false,
    this.updateMessage,
    this.updatePriority,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    PlatformVersionInfo? rootInfo;

    if (json['version_code'] != null) {
      rootInfo = PlatformVersionInfo(
        versionCode: json['version_code'] ?? 0,
        versionName: json['version_name'] ?? '',
        minSupportedVersion: json['min_supported_version'] ?? 0,
        forceUpdateVersions:
        (json['force_update_versions'] as List?)?.cast<int>() ?? [],
      );
    }

    return VersionInfo(
      android: json['android'] != null
          ? PlatformVersionInfo.fromJson(json['android'])
          : null,
      ios: json['ios'] != null
          ? PlatformVersionInfo.fromJson(json['ios'])
          : null,
      root: rootInfo,
      gracePeriodDays:
      json['grace_period_days'] ?? UpdateConfig.defaultGracePeriod,
      updateType: json['update_type'] ?? UpdateConfig.updateTypeOptional,
      killSwitch: json['kill_switch'] ?? false,
      updateMessage: json['update_message'],
      updatePriority: json['update_priority'],
    );
  }

  PlatformVersionInfo? getPlatformInfo(bool isAndroid) {
    return isAndroid ? (android ?? root) : (ios ?? root);
  }

  int? getVersionCode(bool isAndroid) =>
      getPlatformInfo(isAndroid)?.versionCode;

  int? getMinSupportedVersion(bool isAndroid) =>
      getPlatformInfo(isAndroid)?.minSupportedVersion;

  List<int> getForceUpdateVersions(bool isAndroid) =>
      getPlatformInfo(isAndroid)?.forceUpdateVersions ?? [];

  String? getReleaseNotes(bool isAndroid) =>
      getPlatformInfo(isAndroid)?.releaseNotes;

  String? getVersionName(bool isAndroid) =>
      getPlatformInfo(isAndroid)?.versionName;
}

// Update Decision Result
enum UpdateDecision {
  noUpdateNeeded,
  optionalUpdate,
  recommendedUpdate,
  forceUpdate,
  killSwitch,
}

class UpdateDecisionResult {
  final UpdateDecision decision;
  final VersionInfo? versionInfo;
  final String? message;
  final int? graceDaysRemaining;

  UpdateDecisionResult({
    required this.decision,
    this.versionInfo,
    this.message,
    this.graceDaysRemaining,
  });

  bool get shouldUpdate => decision != UpdateDecision.noUpdateNeeded;

  bool get isForced =>
      decision == UpdateDecision.forceUpdate ||
          decision == UpdateDecision.killSwitch;
}