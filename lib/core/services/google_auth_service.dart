// lib/core/services/google_auth_service.dart

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../utils/shared_prefs_helper.dart';
import '../utils/login_device_info.dart';

class GoogleAuthService {
  // Web Client ID
  static const String WEB_CLIENT_ID =
      '296549560438-3v2mej6urs20joo402dkfv759buucr0c.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: WEB_CLIENT_ID,
  );

  // Sign in with Google and get ID token
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      developer.log(' Starting Google Sign-In Process', name: 'GOOGLE_AUTH');

      // Sign out any existing session
      await _googleSignIn.signOut();
      developer.log(' Cleared existing session', name: 'GOOGLE_AUTH');

      // Launch Google Sign-In UI
      developer.log(' Launching Google Sign-In UI...', name: 'GOOGLE_AUTH');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        developer.log(' User cancelled sign-in', name: 'GOOGLE_AUTH');
        return {'success': false, 'message': 'Sign-in cancelled'};
      }

      developer.log(' Google account selected', name: 'GOOGLE_AUTH');
      developer.log('   Name: ${googleUser.displayName}', name: 'GOOGLE_AUTH');
      developer.log('   Email: ${googleUser.email}', name: 'GOOGLE_AUTH');

      // Get authentication tokens
      developer.log(' Getting authentication tokens...', name: 'GOOGLE_AUTH');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        developer.log(' Failed to get ID token', name: 'GOOGLE_AUTH');
        return {
          'success': false,
          'message': 'Failed to get authentication token',
        };
      }

      developer.log(' ID Token received!', name: 'GOOGLE_AUTH');
      developer.log(
        '   Token length: ${googleAuth.idToken!.length}',
        name: 'GOOGLE_AUTH',
      );
      developer.log(
        '   Token preview: ${googleAuth.idToken!.substring(0, 50)}...',
        name: 'GOOGLE_AUTH',
      );

      // Token validation
      try {
        final parts = googleAuth.idToken!.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );
          developer.log(' Token Payload:', name: 'GOOGLE_AUTH');
          developer.log('   aud: ${payload['aud']}', name: 'GOOGLE_AUTH');
          developer.log('   email: ${payload['email']}', name: 'GOOGLE_AUTH');
          developer.log(
            '   email_verified: ${payload['email_verified']}',
            name: 'GOOGLE_AUTH',
          );

          // Check if audience matches Web Client ID
          if (payload['aud'] == WEB_CLIENT_ID) {
            developer.log(
              '    Token audience matches Web Client ID!',
              name: 'GOOGLE_AUTH',
            );
          } else {
            developer.log('   Token audience mismatch', name: 'GOOGLE_AUTH');
            developer.log('   Expected: $WEB_CLIENT_ID', name: 'GOOGLE_AUTH');
            developer.log('   Got: ${payload['aud']}', name: 'GOOGLE_AUTH');
          }
        }
      } catch (e) {
        developer.log(' Could not decode token: $e', name: 'GOOGLE_AUTH');
      }

      developer.log(' Google Sign-In successful!', name: 'GOOGLE_AUTH');

      return {
        'success': true,
        'idToken': googleAuth.idToken!,
        'user': {
          'name': googleUser.displayName ?? '',
          'email': googleUser.email,
          'photoUrl': googleUser.photoUrl,
        },
      };
    } catch (e, stackTrace) {
      developer.log(' ERROR in Google Sign-In', name: 'GOOGLE_AUTH');
      developer.log('   Error: $e', name: 'GOOGLE_AUTH');
      developer.log('   Stack: $stackTrace', name: 'GOOGLE_AUTH');

      return {
        'success': false,
        'message': 'Google Sign-In failed: ${e.toString()}',
      };
    }
  }

  // Send Google ID token to backend for authentication
  Future<Map<String, dynamic>> loginWithGoogleToken({
    required String idToken,
    String? fcmToken,
    LoginDeviceInfo? deviceInfo,
  }) async {
    try {
      developer.log(' Sending Google token to backend', name: 'GOOGLE_BACKEND');

      // Get base URL
      final baseUrl = await SharedPrefsHelper.getBaseUrl();

      if (baseUrl == null || baseUrl.isEmpty) {
        developer.log(' Base URL is NULL or empty!', name: 'GOOGLE_BACKEND');
        return {
          'success': false,
          'message': 'Configuration error: Base URL not found',
        };
      }

      // Properly construct URL
      final Uri uri = Uri.parse(baseUrl).resolve('api/auth/google-login');

      developer.log(' URL Details:', name: 'GOOGLE_BACKEND');
      developer.log('   Base URL: $baseUrl', name: 'GOOGLE_BACKEND');
      developer.log('   Full URL: ${uri.toString()}', name: 'GOOGLE_BACKEND');
      developer.log(
        '   ID Token: ${idToken.substring(0, 50)}...',
        name: 'GOOGLE_BACKEND',
      );
      developer.log(
        '   FCM Token: ${fcmToken ?? "Not provided"}',
        name: 'GOOGLE_BACKEND',
      );
      developer.log(
        '   Device ID: ${deviceInfo?.deviceId ?? "Not provided"}',
        name: 'GOOGLE_BACKEND',
      );
      developer.log(
        '   Device Name: ${deviceInfo?.deviceName ?? "Not provided"}',
        name: 'GOOGLE_BACKEND',
      );

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'id_token': idToken,
        if (deviceInfo != null) ...deviceInfo.toJson(),
      };

      // Add FCM token if available
      if (fcmToken != null && fcmToken.isNotEmpty) {
        requestBody['fcm_token'] = fcmToken;
      }

      developer.log(' Sending POST request...', name: 'GOOGLE_BACKEND');
      developer.log(
        '   Body: ${json.encode(requestBody)}',
        name: 'GOOGLE_BACKEND',
      );

      // Make API call
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      // Parse response with better error handling
      try {
        final Map<String, dynamic> data = json.decode(response.body);

        if (response.statusCode == 200) {
          developer.log(
            ' Backend authentication successful!',
            name: 'GOOGLE_BACKEND',
          );
          developer.log(
            '   User: ${data['user']?['name'] ?? "Unknown"}',
            name: 'GOOGLE_BACKEND',
          );
          developer.log(
            '   Token: ${data['token']?.toString().substring(0, 20) ?? "No token"}...',
            name: 'GOOGLE_BACKEND',
          );

          return {'success': true, 'data': data};
        } else {
          developer.log(' Backend returned error', name: 'GOOGLE_BACKEND');
          developer.log(
            '   Status: ${response.statusCode}',
            name: 'GOOGLE_BACKEND',
          );
          developer.log(
            '   Message: ${data['message'] ?? "Unknown error"}',
            name: 'GOOGLE_BACKEND',
          );

          return {
            'success': false,
            'message': data['message'] ?? 'Authentication failed',
          };
        }
      } catch (jsonError) {
        developer.log(
          ' Server returned invalid response',
          name: 'GOOGLE_BACKEND',
        );
        developer.log(
          '   Status: ${response.statusCode}',
          name: 'GOOGLE_BACKEND',
        );

        //  Safe substring with length check
        final maxLength = response.body.length > 200
            ? 200
            : response.body.length;
        developer.log(
          '   Response Preview: ${response.body.substring(0, maxLength)}',
          name: 'GOOGLE_BACKEND',
        );

        if (response.body.length > 200) {
          developer.log(
            '   Response Length: ${response.body.length} characters',
            name: 'GOOGLE_BACKEND',
          );
        }

        String errorMessage = 'Server error. Please try again later.';

        if (response.statusCode == 500) {
          errorMessage =
              'Server is experiencing issues. Please contact support.';
        } else if (response.statusCode == 503) {
          errorMessage = 'Server is temporarily unavailable. Please try again.';
        }

        return {'success': false, 'message': errorMessage};
      }
    } catch (e, stackTrace) {
      developer.log(' CRITICAL ERROR', name: 'GOOGLE_BACKEND');
      developer.log('   Error: $e', name: 'GOOGLE_BACKEND');
      developer.log('   Stack: $stackTrace', name: 'GOOGLE_BACKEND');

      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      developer.log(' Signed out from Google', name: 'GOOGLE_AUTH');
    } catch (e) {
      developer.log(' Sign out error: $e', name: 'GOOGLE_AUTH');
    }
  }

  // Check if user is currently signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Get current Google user (if signed in)
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return _googleSignIn.currentUser;
  }
}
