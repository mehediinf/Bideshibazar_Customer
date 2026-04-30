// lib/core/providers/user_provider.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../utils/shared_prefs_helper.dart';

class UserProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  int? _userId;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _userImage;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String? get userImage => _userImage;
  String? get token => _token;

  // Get display contact (email or phone)
  String get displayContact {
    // If email looks like a real email, show it
    if (_userEmail != null &&
        _userEmail!.isNotEmpty &&
        _userEmail!.contains('@') &&
        !_userEmail!.contains('noemail')) {
      return _userEmail!;
    }
    // Otherwise show phone
    if (_userPhone != null && _userPhone!.isNotEmpty) {
      return _userPhone!;
    }
    return 'No contact info';
  }

  // Initialize user data from SharedPreferences

  Future<void> loadUserData() async {
    try {
      debugPrint(' [UserProvider] Loading user data...');

      _isLoggedIn = await SharedPrefsHelper.isLoggedIn();
      debugPrint('   isLoggedIn: $_isLoggedIn');

      if (_isLoggedIn) {
        final userData = await SharedPrefsHelper.getUserData();

        _token = userData['token'];
        _userId = userData['userId'];
        _userName = userData['userName'];
        _userEmail = userData['userEmail'];
        _userPhone = userData['userPhone'];
        _userImage = userData['userImage'];

        debugPrint(' [UserProvider] User data loaded successfully');
        debugPrint('   Token: ${_token != null ? '${_token!.substring(0, min(20, _token!.length))}...' : 'NULL'}');
        debugPrint('   UserId: $_userId');
        debugPrint('   UserName: $_userName');
      } else {
        debugPrint(' [UserProvider] User not logged in');

        // Clear all data if not logged in
        _token = null;
        _userId = null;
        _userName = null;
        _userEmail = null;
        _userPhone = null;
        _userImage = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint(' [UserProvider] Error loading user data: $e');
      _isLoggedIn = false;
      _token = null;
      notifyListeners();
    }
  }

  // Set user data after login - accepting your API response structure
  Future<void> setUserData({
    required String token,
    required int userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    String? userImage,
  }) async {
    try {
      _token = token;
      _userId = userId;
      _userName = userName;
      _userEmail = userEmail;
      _userPhone = userPhone;
      _userImage = userImage;
      _isLoggedIn = true;

      await SharedPrefsHelper.saveLoginData(
        token: token,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        userImage: userImage,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting user data: $e');
    }
  }

  // Alternative method: Set user data from API response map
  Future<void> setUserDataFromApi({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    await setUserData(
      token: token,
      userId: user['id'],
      userName: user['name'] ?? '',
      userEmail: user['email'] ?? '',
      userPhone: user['phone'] ?? '',
      userImage: user['image'],
    );
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? email,
    String? phone,
    String? image,
  }) async {
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    if (phone != null) _userPhone = phone;
    if (image != null) _userImage = image;

    await SharedPrefsHelper.saveLoginData(
      token: _token!,
      userId: _userId!,
      userName: _userName!,
      userEmail: _userEmail ?? '',
      userPhone: _userPhone ?? '',
      userImage: _userImage,
    );

    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    await SharedPrefsHelper.clearAll();

    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    _userPhone = null;
    _userImage = null;
    _isLoggedIn = false;

    notifyListeners();
  }
}