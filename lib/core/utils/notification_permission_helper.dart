// lib/core/utils/notification_permission_helper.dart

import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class NotificationPermissionHelper {
  /// Request notification permission (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    try {
      developer.log('📱 Checking notification permission...', name: 'NOTIFICATION_PERMISSION');

      // Check current permission status
      PermissionStatus status = await Permission.notification.status;

      developer.log('   Current status: $status', name: 'NOTIFICATION_PERMISSION');

      if (status.isGranted) {
        developer.log('✅ Notification permission already granted', name: 'NOTIFICATION_PERMISSION');
        return true;
      }

      if (status.isDenied) {
        developer.log('⚠️ Permission denied, requesting...', name: 'NOTIFICATION_PERMISSION');

        // Request permission
        status = await Permission.notification.request();

        developer.log('   New status: $status', name: 'NOTIFICATION_PERMISSION');

        if (status.isGranted) {
          developer.log('✅ Notification permission granted', name: 'NOTIFICATION_PERMISSION');
          return true;
        } else if (status.isPermanentlyDenied) {
          developer.log('❌ Permission permanently denied', name: 'NOTIFICATION_PERMISSION');
          developer.log('   User needs to enable from Settings', name: 'NOTIFICATION_PERMISSION');
          return false;
        } else {
          developer.log('❌ Permission denied', name: 'NOTIFICATION_PERMISSION');
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        developer.log('❌ Permission permanently denied', name: 'NOTIFICATION_PERMISSION');
        developer.log('   Opening app settings...', name: 'NOTIFICATION_PERMISSION');
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      developer.log('❌ Error requesting notification permission: $e', name: 'NOTIFICATION_PERMISSION');
      return false;
    }
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      PermissionStatus status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      developer.log('❌ Error checking permission: $e', name: 'NOTIFICATION_PERMISSION');
      return false;
    }
  }
}