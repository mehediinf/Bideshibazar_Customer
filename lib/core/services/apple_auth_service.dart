// lib/core/services/apple_auth_service.dart

import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../utils/shared_prefs_helper.dart';
import '../utils/login_device_info.dart';

class AppleAuthService {
  static final AppleAuthService _instance = AppleAuthService._internal();
  factory AppleAuthService() => _instance;
  AppleAuthService._internal();

  // Generate nonce for Apple Sign-In security
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // Hash nonce with SHA256
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  //Check if running on simulator
  bool _isSimulator() {
    try {
      return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
    } catch (e) {
      return false;
    }
  }

  // Sign in with Apple
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      developer.log(' Starting Apple Sign-In...', name: 'APPLE_AUTH');

      //  Check if simulator
      if (_isSimulator()) {
        developer.log(
          '  WARNING: Running on iOS Simulator',
          name: 'APPLE_AUTH',
        );
        developer.log(
          '  Apple Sign-In requires REAL DEVICE',
          name: 'APPLE_AUTH',
        );
        return {
          'success': false,
          'message':
              'Apple Sign-In requires a real device. Please test on a physical iPhone.',
        };
      }

      developer.log(' Platform: iOS (Real Device)', name: 'APPLE_AUTH');

      // Check availability first
      final isAvailable = await SignInWithApple.isAvailable();
      developer.log(
        ' Apple Sign-In Available: $isAvailable',
        name: 'APPLE_AUTH',
      );

      if (!isAvailable) {
        developer.log(
          ' Apple Sign-In not available on this device',
          name: 'APPLE_AUTH',
        );
        return {
          'success': false,
          'message': 'Apple Sign-In is not available on this device',
        };
      }

      // Generate nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      developer.log(' Nonce generated', name: 'APPLE_AUTH');
      developer.log(
        ' Requesting credentials from Apple...',
        name: 'APPLE_AUTH',
      );

      // Request Apple Sign-In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      developer.log(
        ' Apple credential received successfully!',
        name: 'APPLE_AUTH',
      );
      developer.log(
        '   User ID: ${credential.userIdentifier ?? "N/A"}',
        name: 'APPLE_AUTH',
      );
      developer.log(
        '   Email: ${credential.email ?? "N/A"}',
        name: 'APPLE_AUTH',
      );
      developer.log(
        '   Given Name: ${credential.givenName ?? "N/A"}',
        name: 'APPLE_AUTH',
      );
      developer.log(
        '   Family Name: ${credential.familyName ?? "N/A"}',
        name: 'APPLE_AUTH',
      );
      developer.log(
        '   FULL Identity Token: ${credential.identityToken}',
        name: 'APPLE_AUTH',
      );

      // Extract user info
      String email = credential.email ?? '';
      String fullName = '';

      if (credential.givenName != null || credential.familyName != null) {
        fullName =
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim();
      }

      // Important: Email and name are only provided on FIRST sign-in
      if (email.isEmpty) {
        developer.log(
          ' Email not provided (user previously signed in)',
          name: 'APPLE_AUTH',
        );
        developer.log(
          '   Backend should use cached data for this user',
          name: 'APPLE_AUTH',
        );
      }

      if (fullName.isEmpty) {
        developer.log(
          '  Full name not provided (user previously signed in)',
          name: 'APPLE_AUTH',
        );
      }

      // Validate identity token
      if (credential.identityToken == null ||
          credential.identityToken!.isEmpty) {
        developer.log(' Identity token is missing!', name: 'APPLE_AUTH');
        return {
          'success': false,
          'message': 'Failed to get authentication token from Apple',
        };
      }

      developer.log('Apple Sign-In successful!', name: 'APPLE_AUTH');

      return {
        'success': true,
        'identityToken': credential.identityToken!,
        'userIdentifier': credential.userIdentifier ?? '',
        'email': email,
        'fullName': fullName,
        'user': {
          'id': credential.userIdentifier ?? '',
          'email': email,
          'name': fullName,
        },
      };
    } on SignInWithAppleAuthorizationException catch (e) {
      developer.log(' Apple Sign-In Authorization Failed', name: 'APPLE_AUTH');
      developer.log('   Error Code: ${e.code}', name: 'APPLE_AUTH');
      developer.log('   Error Message: ${e.message}', name: 'APPLE_AUTH');

      return {'success': false, 'message': _getAuthErrorMessage(e)};
    } catch (e, stackTrace) {
      developer.log(
        ' Apple Sign-In Failed (Unexpected Error)',
        name: 'APPLE_AUTH',
      );
      developer.log('   Error: $e', name: 'APPLE_AUTH');
      developer.log('   Stack: $stackTrace', name: 'APPLE_AUTH');

      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  // Send Apple identity token to backend for authentication
  Future<Map<String, dynamic>> loginWithAppleToken({
    required String identityToken,
    String? userIdentifier,
    String? email,
    String? fullName,
    String? guestId,
    String? fcmToken,
    LoginDeviceInfo? deviceInfo,
  }) async {
    try {
      developer.log(
        ' Sending Apple token to backend...',
        name: 'APPLE_BACKEND',
      );

      final baseUrl = await SharedPrefsHelper.getBaseUrl();

      if (baseUrl == null || baseUrl.isEmpty) {
        developer.log(' Base URL is not configured', name: 'APPLE_BACKEND');
        return {
          'success': false,
          'message': 'Server configuration error. Please contact support.',
        };
      }

      final url = '${baseUrl}api/auth/apple-login';

      developer.log(' URL: $url', name: 'APPLE_BACKEND');
      developer.log(
        ' User Identifier: ${userIdentifier ?? "N/A"}',
        name: 'APPLE_BACKEND',
      );
      developer.log(' Email: ${email ?? "N/A"}', name: 'APPLE_BACKEND');
      developer.log(' Full Name: ${fullName ?? "N/A"}', name: 'APPLE_BACKEND');
      developer.log(' Guest ID: ${guestId ?? "N/A"}', name: 'APPLE_BACKEND');
      developer.log(
        ' FCM Token: ${fcmToken != null && fcmToken.isNotEmpty ? "Present" : "Not provided"}',
        name: 'APPLE_BACKEND',
      );
      developer.log(
        ' Device ID: ${deviceInfo?.deviceId ?? "N/A"}',
        name: 'APPLE_BACKEND',
      );
      developer.log(
        ' Device Name: ${deviceInfo?.deviceName ?? "N/A"}',
        name: 'APPLE_BACKEND',
      );
      developer.log(
        ' Identity Token Length: ${identityToken.length} chars',
        name: 'APPLE_BACKEND',
      );

      final requestBody = {
        'id_token': identityToken,
        'user_identifier': userIdentifier ?? '',
        'email': email ?? '',
        'full_name': fullName ?? '',
        'guest_id': guestId ?? '',
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        if (deviceInfo != null) ...deviceInfo.toJson(),
      };

      developer.log(' Sending request...', name: 'APPLE_BACKEND');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your internet connection.',
              );
            },
          );

      developer.log(' Response received', name: 'APPLE_BACKEND');
      developer.log(
        '   Status Code: ${response.statusCode}',
        name: 'APPLE_BACKEND',
      );
      developer.log(
        '   Response Body: ${response.body}',
        name: 'APPLE_BACKEND',
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        developer.log(
          ' Backend authentication successful!',
          name: 'APPLE_BACKEND',
        );
        developer.log(
          '   User: ${responseData['user']['name']}',
          name: 'APPLE_BACKEND',
        );
        developer.log(
          '   Email: ${responseData['user']['email'] ?? "N/A"}',
          name: 'APPLE_BACKEND',
        );
        developer.log(
          '   Token: ${responseData['token'].substring(0, 20)}...',
          name: 'APPLE_BACKEND',
        );

        return {
          'success': true,
          'data': {
            'user': responseData['user'],
            'token': responseData['token'],
          },
          'message': responseData['message'],
        };
      } else {
        developer.log(' Backend authentication failed', name: 'APPLE_BACKEND');
        developer.log(
          '   Status: ${response.statusCode}',
          name: 'APPLE_BACKEND',
        );
        developer.log(
          '   Message: ${responseData['message'] ?? "Unknown error"}',
          name: 'APPLE_BACKEND',
        );

        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Authentication failed. Please try again.',
        };
      }
    } catch (e, stackTrace) {
      developer.log(' Backend request error', name: 'APPLE_BACKEND');
      developer.log('   Error: $e', name: 'APPLE_BACKEND');
      developer.log('   Stack: $stackTrace', name: 'APPLE_BACKEND');

      if (e.toString().contains('timeout')) {
        return {
          'success': false,
          'message':
              'Connection timeout. Please check your internet connection.',
        };
      }

      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  // Get user-friendly authorization error message
  String _getAuthErrorMessage(SignInWithAppleAuthorizationException error) {
    developer.log(
      ' Parsing authorization error code: ${error.code}',
      name: 'APPLE_AUTH',
    );

    switch (error.code) {
      case AuthorizationErrorCode.canceled:
        return 'Sign-in was canceled';

      case AuthorizationErrorCode.failed:
        return 'Sign-in failed. Please try again.';

      case AuthorizationErrorCode.invalidResponse:
        return 'Invalid response from Apple. Please try again.';

      case AuthorizationErrorCode.notHandled:
        return 'Sign-in not handled properly. Please try again.';

      case AuthorizationErrorCode.notInteractive:
        return 'Cannot show sign-in dialog. Please try again.';

      case AuthorizationErrorCode.unknown:
        // Error code 1000 often means configuration issue
        developer.log(
          '  Unknown error (1000) - Usually a configuration issue',
          name: 'APPLE_AUTH',
        );
        return 'Apple Sign-In is not properly configured. Please check:\n'
            '1. Xcode: Enable "Sign In with Apple" capability\n'
            '2. Apple Developer: Enable capability in App ID\n'
            '3. Test on a real iPhone device (not simulator)';

      default:
        return 'An error occurred. Please try again.';
    }
  }

  // Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('canceled') || errorString.contains('cancelled')) {
      return 'Sign-in was canceled';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (errorString.contains('timeout')) {
      return 'Connection timeout. Please try again.';
    } else {
      return 'Apple Sign-In failed. Please try again.';
    }
  }

  // Check if Apple Sign-In is available on this device
  Future<bool> isAvailable() async {
    try {
      // Check if simulator
      if (_isSimulator()) {
        developer.log(' Apple Sign-In: Simulator detected', name: 'APPLE_AUTH');
        return false;
      }

      // Check platform availability
      final available = await SignInWithApple.isAvailable();
      developer.log(
        ' Apple Sign-In availability: $available',
        name: 'APPLE_AUTH',
      );

      return available;
    } catch (e) {
      developer.log(
        ' Error checking Apple Sign-In availability: $e',
        name: 'APPLE_AUTH',
      );
      return false;
    }
  }
}
