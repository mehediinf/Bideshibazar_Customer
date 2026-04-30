//lib/core/services/update_manager.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';
import '../../data/models/update_models.dart';

class UpdateManager {
  static const String _tag = 'UpdateManager';

  final BuildContext context;
  final String apiUrl;
  final bool debugMode;

  UpdateManager({
    required this.context,
    required this.apiUrl,
    this.debugMode = false,
  });

  Future<UpdateDecisionResult> checkForUpdates() async {
    try {
      if (!await _shouldCheckNow()) {
        _log('Skipping check - too soon since last check');
        return UpdateDecisionResult(decision: UpdateDecision.noUpdateNeeded);
      }

      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(Duration(seconds: UpdateConfig.apiTimeoutSeconds));

      if (response.statusCode != 200) {
        _log('API returned ${response.statusCode}');
        return UpdateDecisionResult(decision: UpdateDecision.noUpdateNeeded);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['success'] != true) {
        _log('API success = false');
        return UpdateDecisionResult(decision: UpdateDecision.noUpdateNeeded);
      }

      if (data['version_info'] == null) {
        _log('No version_info in response');
        return UpdateDecisionResult(decision: UpdateDecision.noUpdateNeeded);
      }

      final versionInfo = VersionInfo.fromJson(data['version_info'] as Map<String, dynamic>);
      await _saveLastCheckTime();

      return await _processUpdateInfo(versionInfo);
    } catch (e) {
      _log('Error checking updates: $e');
      return UpdateDecisionResult(decision: UpdateDecision.noUpdateNeeded);
    }
  }

  // Process version information and decide update strategy
  Future<UpdateDecisionResult> _processUpdateInfo(VersionInfo info) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = int.parse(packageInfo.buildNumber);
    final isAndroid = Platform.isAndroid;

    // Get platform-specific version info
    final latestVersion = info.getVersionCode(isAndroid);
    final minSupported = info.getMinSupportedVersion(isAndroid);
    final forceVersions = info.getForceUpdateVersions(isAndroid);

    if (latestVersion == null) {
      _log('No version info for platform');
      return UpdateDecisionResult(
        decision: UpdateDecision.noUpdateNeeded,
      );
    }

    _log('Platform: ${isAndroid ? "Android" : "iOS"}');
    _log('Current: $currentVersion, Latest: $latestVersion, Min: $minSupported');
    _log('Force versions: $forceVersions, Kill switch: ${info.killSwitch}');

    // Priority 1: Kill Switch
    if (info.killSwitch) {
      return UpdateDecisionResult(
        decision: UpdateDecision.killSwitch,
        versionInfo: info,
        message: info.updateMessage ?? 'App update required',
      );
    }

    // Priority 2: Specific version force update
    if (forceVersions.contains(currentVersion)) {
      return UpdateDecisionResult(
        decision: UpdateDecision.forceUpdate,
        versionInfo: info,
        message: info.updateMessage ?? 'Critical update required',
      );
    }

    // Already on latest version
    if (currentVersion >= latestVersion) {
      _log('App is up to date');
      return UpdateDecisionResult(decision: UpdateDecision.noUpdateNeeded);
    }

    // Priority 3: Below minimum supported version
    if (minSupported != null && currentVersion < minSupported) {
      return UpdateDecisionResult(
        decision: UpdateDecision.forceUpdate,
        versionInfo: info,
        message: 'Your app version is no longer supported',
      );
    }

    // Priority 4: Grace period logic
    final graceDaysRemaining = await _getGraceDaysRemaining(
      latestVersion,
      info.gracePeriodDays,
    );

    final isGraceOver = graceDaysRemaining <= 0;

    if (isGraceOver && info.updateType == UpdateConfig.updateTypeForce) {
      return UpdateDecisionResult(
        decision: UpdateDecision.forceUpdate,
        versionInfo: info,
        message: 'Grace period ended. Please update the app',
      );
    } else if (info.updateType == UpdateConfig.updateTypeForce) {
      return UpdateDecisionResult(
        decision: UpdateDecision.recommendedUpdate,
        versionInfo: info,
        graceDaysRemaining: graceDaysRemaining,
        message: info.updateMessage ?? 'A new update is available',
      );
    } else {
      return UpdateDecisionResult(
        decision: UpdateDecision.optionalUpdate,
        versionInfo: info,
        message: info.updateMessage ?? 'A new version is available',
      );
    }
  }

  // Show appropriate update UI based on decision
  Future<void> showUpdateUI(UpdateDecisionResult result) async {
    if (!result.shouldUpdate) return;

    if (result.isForced) {
      await _showForceUpdate(
        title: result.decision == UpdateDecision.killSwitch
            ? 'App Disabled'
            : 'Update Required',
        message: result.message ?? 'Please update your app',
        versionInfo: result.versionInfo,
        isKillSwitch: result.decision == UpdateDecision.killSwitch,
      );
    } else {
      await _showOptionalUpdate(
        title: 'New Update Available',
        message: result.message ?? 'A newer version is available',
        versionInfo: result.versionInfo,
        graceDaysLeft: result.graceDaysRemaining,
      );
    }
  }

  // Check if enough time passed since last check
  Future<bool> _shouldCheckNow() async {
    if (debugMode) return true;

    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(UpdateConfig.prefLastCheckTime);

    if (lastCheck == null) return true;

    final hoursPassed = (DateTime.now().millisecondsSinceEpoch - lastCheck) /
        (1000 * 60 * 60);

    return hoursPassed >= UpdateConfig.minCheckIntervalHours;
  }

  // Save last check time
  Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      UpdateConfig.prefLastCheckTime,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Get remaining grace period days
  Future<int> _getGraceDaysRemaining(int version, int graceDays) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${UpdateConfig.prefGracePrefix}$version';

    final firstSeenTime = prefs.getInt(key);

    if (firstSeenTime == null) {
      // First time seeing this version
      await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
      return graceDays;
    }

    final daysPassed = (DateTime.now().millisecondsSinceEpoch - firstSeenTime) ~/
        (1000 * 60 * 60 * 24);

    return graceDays - daysPassed;
  }

  // Show force update dialog (non-dismissible)
  Future<void> _showForceUpdate({
    required String title,
    required String message,
    VersionInfo? versionInfo,
    bool isKillSwitch = false,
  }) async {
    // Try Android in-app update first
    if (Platform.isAndroid && !isKillSwitch) {
      final success = await _tryInAppUpdate(immediate: true);
      if (success) return;
    }

    // Show dialog
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isKillSwitch ? Icons.block : Icons.system_update,
                  size: 64,
                  color: isKillSwitch ? Colors.red : Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
                if (versionInfo != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Latest Version: ${versionInfo.getVersionName(Platform.isAndroid) ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (versionInfo?.getReleaseNotes(Platform.isAndroid) != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'New Features:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    versionInfo!.getReleaseNotes(Platform.isAndroid)!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (isKillSwitch) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'App Temporarily Disabled',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openStore(),
                icon: const Icon(Icons.download),
                label: const Text(
                  'Update Now',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isKillSwitch ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show optional update dialog
  Future<void> _showOptionalUpdate({
    required String title,
    required String message,
    VersionInfo? versionInfo,
    int? graceDaysLeft,
  }) async {
    // Check if user dismissed this version
    if (versionInfo != null) {
      final versionCode = versionInfo.getVersionCode(Platform.isAndroid);
      if (versionCode != null && await _wasVersionDismissed(versionCode)) {
        return;
      }
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.new_releases,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              if (versionInfo?.getVersionName(Platform.isAndroid) != null) ...[
                const SizedBox(height: 8),
                Text(
                  'New Version: ${versionInfo!.getVersionName(Platform.isAndroid)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (graceDaysLeft != null && graceDaysLeft > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '$graceDaysLeft days remaining',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (versionInfo?.getReleaseNotes(Platform.isAndroid) != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What\'s New:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  versionInfo!.getReleaseNotes(Platform.isAndroid)!,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final versionCode = versionInfo?.getVersionCode(Platform.isAndroid);
              if (versionCode != null) {
                await _markVersionDismissed(versionCode);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (context.mounted) Navigator.pop(context);
              _openStore();
            },
            icon: const Icon(Icons.download),
            label: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Try Android in-app update
  Future<bool> _tryInAppUpdate({bool immediate = false}) async {
    if (!Platform.isAndroid) return false;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        _log('No in-app update available');
        return false;
      }

      if (immediate) {
        await InAppUpdate.performImmediateUpdate();
      } else {
        await InAppUpdate.startFlexibleUpdate();
        // Complete update when downloaded
        await InAppUpdate.completeFlexibleUpdate();
      }

      return true;
    } catch (e) {
      _log('In-app update failed: $e');
      return false;
    }
  }

  // Open app store
  Future<void> _openStore() async {
    final packageInfo = await PackageInfo.fromPlatform();

    final Uri url;

    if (Platform.isAndroid) {
      final packageName = packageInfo.packageName;
      url = Uri.parse(UpdateConfig.getPlayStoreUrl(packageName));
    } else if (Platform.isIOS) {
      url = Uri.parse(UpdateConfig.getAppStoreUrl(UpdateConfig.iosAppStoreId));
    } else {
      _log('Unsupported platform');
      return;
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _log('Could not launch $url');
      }
    } catch (e) {
      _log('Error launching store: $e');
    }
  }

  // Check if version was dismissed
  Future<bool> _wasVersionDismissed(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedVersion = prefs.getInt(UpdateConfig.prefDismissedVersion);
    return dismissedVersion == versionCode;
  }

  // Mark version as dismissed
  Future<void> _markVersionDismissed(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(UpdateConfig.prefDismissedVersion, versionCode);
  }

  // Resume immediate update if in progress (Android)
  Future<void> resumeImmediateUpdateIfNeeded() async {
    if (!Platform.isAndroid) return;

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      _log('Resume update error: $e');
    }
  }

  // Log helper
  void _log(String message) {
    if (debugMode) {
      debugPrint('[$_tag] $message');
    }
  }
}