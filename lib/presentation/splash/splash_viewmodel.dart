// lib/presentation/splash/splash_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/services/update_manager.dart';
import '../../data/models/update_models.dart';

class SplashViewModel extends ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;

    await _checkForUpdates(context);
    if (!context.mounted) return;

    await _navigateToNextScreen(context);
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    try {
      if (kDebugMode) {
        await _clearUpdatePrefsForDebug();
      }

      final updateManager = UpdateManager(
        context: context,
        apiUrl: '${UpdateConfig.baseUrl}${UpdateConfig.versionEndpoint}',
        debugMode: kDebugMode,
      );

      final result = await updateManager.checkForUpdates();

      debugPrint('[Splash] Update decision: ${result.decision.name}');
      debugPrint('[Splash] Should update: ${result.shouldUpdate}');
      debugPrint('[Splash] Is forced: ${result.isForced}');

      if (result.isForced) {
        await updateManager.showUpdateUI(result);
        return;
      }

      if (result.shouldUpdate) {
        await updateManager.showUpdateUI(result);
      }

    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  Future<void> _clearUpdatePrefsForDebug() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(UpdateConfig.prefDismissedVersion);
    await prefs.remove(UpdateConfig.prefLastCheckTime);

    final graceKeys = prefs
        .getKeys()
        .where((k) => k.startsWith(UpdateConfig.prefGracePrefix))
        .toList();
    for (final key in graceKeys) {
      await prefs.remove(key);
    }
    debugPrint('[UpdateManager] Debug: All update prefs cleared');
  }

  Future<void> _navigateToNextScreen(BuildContext context) async {
    if (!context.mounted) return;

    try {
      final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
      if (!context.mounted) return;

      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/welcome');
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }
}
