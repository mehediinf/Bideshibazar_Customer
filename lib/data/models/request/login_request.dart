// lib/data/models/request/login_request.dart

import '../../../core/utils/login_device_info.dart';

class LoginRequest {
  final String email;
  final String password;
  final String fcmToken;
  final String? guestId;
  final String deviceId;
  final String deviceName;
  final String appVersion;
  final String osVersion;

  LoginRequest({
    required this.email,
    required this.password,
    this.fcmToken = '',
    this.guestId,
    this.deviceId = '',
    this.deviceName = '',
    this.appVersion = '',
    this.osVersion = '',
  });

  factory LoginRequest.fromDeviceInfo({
    required String email,
    required String password,
    String fcmToken = '',
    String? guestId,
    required LoginDeviceInfo deviceInfo,
  }) {
    return LoginRequest(
      email: email,
      password: password,
      fcmToken: fcmToken,
      guestId: guestId,
      deviceId: deviceInfo.deviceId,
      deviceName: deviceInfo.deviceName,
      appVersion: deviceInfo.appVersion,
      osVersion: deviceInfo.osVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fcm_token': fcmToken,
      'guest_id': guestId,
      'device_id': deviceId,
      'device_name': deviceName,
      'app_version': appVersion,
      'os_version': osVersion,
    };
  }
}
