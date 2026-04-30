// lib/core/utils/shared_prefs_helper.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPrefsHelper {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserImage = 'user_image';
  static const String _keySelectedAddress = 'selected_address';
  static const String _keyLocationPermissionAsked = 'location_permission_asked';
  static const String _keyLocationPermissionGranted = 'location_permission_granted';
  static const String _keySellerIds = 'seller_ids';
  static const String _keyFcmToken = 'fcm_token';
  static const String _keyBaseUrl = 'base_url';
  static const String _keySeenBlogPostId = 'seen_blog_post_id';

  // Save login data
  static Future<void> saveLoginData({
    required String token,
    required int userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    String? userImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyUserEmail, userEmail);
    await prefs.setString(_keyUserPhone, userPhone);
    if (userImage != null) {
      await prefs.setString(_keyUserImage, userImage);
    }
  }

  // Get token (auth token)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Alias for getToken (for consistency with other services)
  static Future<String?> getAuthToken() async {
    return await getToken();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all data (logout) - PRESERVES address, FCM token, and base URL
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    // Preserve important data before clearing
    final fcmToken = prefs.getString(_keyFcmToken);
    final baseUrl = prefs.getString(_keyBaseUrl);
    final selectedAddress = prefs.getString(_keySelectedAddress);
    final locationPermissionAsked = prefs.getBool(_keyLocationPermissionAsked);
    final locationPermissionGranted = prefs.getBool(_keyLocationPermissionGranted);

    // Clear everything
    await prefs.clear();

    // Restore preserved data
    if (fcmToken != null) {
      await prefs.setString(_keyFcmToken, fcmToken);
    }
    if (baseUrl != null) {
      await prefs.setString(_keyBaseUrl, baseUrl);
    }
    if (selectedAddress != null) {
      await prefs.setString(_keySelectedAddress, selectedAddress);
    }
    if (locationPermissionAsked != null) {
      await prefs.setBool(_keyLocationPermissionAsked, locationPermissionAsked);
    }
    if (locationPermissionGranted != null) {
      await prefs.setBool(_keyLocationPermissionGranted, locationPermissionGranted);
    }
  }

  // Get user data
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_keyToken),
      'userId': prefs.getInt(_keyUserId),
      'userName': prefs.getString(_keyUserName),
      'userEmail': prefs.getString(_keyUserEmail),
      'userPhone': prefs.getString(_keyUserPhone),
      'userImage': prefs.getString(_keyUserImage),
    };
  }


  // Save FCM token
  static Future<void> saveFcmToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFcmToken, fcmToken);
  }

  // Get FCM token
  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFcmToken);
  }

  //Clear FCM token
  static Future<void> clearFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFcmToken);
  }


  // Save base URL
  static Future<void> saveBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, baseUrl);
  }

  // Get base URL
  static Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    // Return saved base URL or default
    // return prefs.getString(_keyBaseUrl) ?? 'https://bideshibazar.com/';
    return prefs.getString(_keyBaseUrl) ?? 'https://dev.bideshibazar.com/';
  }

  //Clear base URL
  static Future<void> clearBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBaseUrl);
  }

  //Save selected address - Address persists across sessions
  static Future<void> saveSelectedAddress(Map<String, dynamic> addressJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedAddress, json.encode(addressJson));
  }

  //Get selected address - Always available unless explicitly cleared
  static Future<Map<String, dynamic>?> getSelectedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final String? addressString = prefs.getString(_keySelectedAddress);

    if (addressString != null && addressString.isNotEmpty) {
      try {
        return json.decode(addressString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Clear selected address - Only call this when user explicitly wants to change address
  static Future<void> clearSelectedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedAddress);
  }

  // Check if location permission was asked before
  static Future<bool> wasLocationPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLocationPermissionAsked) ?? false;
  }

  // Mark that location permission was asked
  static Future<void> setLocationPermissionAsked(bool asked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLocationPermissionAsked, asked);
  }

  // Check if location permission was granted
  static Future<bool> isLocationPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLocationPermissionGranted) ?? false;
  }

  // Set location permission status
  static Future<void> setLocationPermissionGranted(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLocationPermissionGranted, granted);
  }


  // Save seller IDs
  static Future<void> saveSellerIds(List<int> sellerIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySellerIds, json.encode(sellerIds));
  }

  // Get seller IDs
  static Future<List<int>> getSellerIds() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sellerIdsString = prefs.getString(_keySellerIds);

    if (sellerIdsString != null && sellerIdsString.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(sellerIdsString);
        return decoded.map((id) => id as int).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // Check if seller IDs exist
  static Future<bool> hasSellerIds() async {
    final sellerIds = await getSellerIds();
    return sellerIds.isNotEmpty;
  }

  //Clear seller IDs
  static Future<void> clearSellerIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySellerIds);
  }

  static Future<void> saveSeenBlogPostId(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySeenBlogPostId, postId);
  }

  static Future<int?> getSeenBlogPostId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySeenBlogPostId);
  }

  static Future<void> clearSeenBlogPostId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySeenBlogPostId);
  }



  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  // Get user mobile/phone
  static Future<String?> getUserMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserPhone);
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Get user image
  static Future<String?> getUserImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserImage);
  }


  // Save delivery address (alias for consistency)
  static Future<void> saveSavedAddress(Map<String, dynamic> address) async {
    await saveSelectedAddress(address);
  }

  // Get saved address (alias for consistency)
  static Future<Map<String, dynamic>?> getSavedAddress() async {
    return await getSelectedAddress();
  }
}
