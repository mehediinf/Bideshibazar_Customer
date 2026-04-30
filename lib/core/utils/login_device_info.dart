import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LoginDeviceInfo {
  final String deviceId;
  final String deviceName;
  final String appVersion;
  final String osVersion;

  const LoginDeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.appVersion,
    required this.osVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'app_version': appVersion,
      'os_version': osVersion,
    };
  }
}

class LoginDeviceInfoCollector {
  static const String _deviceIdKey = 'login_device_id';

  static Future<LoginDeviceInfo> collect() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();

    var deviceId = prefs.getString(_deviceIdKey) ?? '';
    if (deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return LoginDeviceInfo(
      deviceId: deviceId,
      deviceName: _buildDeviceName(),
      appVersion: _buildAppVersion(packageInfo),
      osVersion: _buildOsVersion(),
    );
  }

  static String _buildDeviceName() {
    final platformName = _capitalize(Platform.operatingSystem);
    return '$platformName Device';
  }

  static String _buildAppVersion(PackageInfo packageInfo) {
    final buildNumber = packageInfo.buildNumber.trim();
    if (buildNumber.isEmpty) {
      return packageInfo.version;
    }
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  static String _buildOsVersion() {
    return Platform.operatingSystemVersion.trim();
  }

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
