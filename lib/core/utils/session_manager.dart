import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final Logger _logger = Logger();

  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserImage = 'user_image';
  static const String _keyGuestId = 'guest_id';

  Future<void> saveSession({
    required String token,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);

    if (userId != null) await prefs.setString(_keyUserId, userId);
    if (userName != null) await prefs.setString(_keyUserName, userName);
    if (userEmail != null) await prefs.setString(_keyUserEmail, userEmail);
    if (userPhone != null) await prefs.setString(_keyUserPhone, userPhone);
    if (userImage != null) await prefs.setString(_keyUserImage, userImage);

    _logger.d('Session saved: userId=$userId');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserPhone);
  }

  Future<String?> getUserImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserImage);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserImage);

    _logger.d('User logged out');
  }

  Future<String> getGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString(_keyGuestId);

    if (guestId == null || guestId.isEmpty) {
      guestId = _generateGuestId();
      await prefs.setString(_keyGuestId, guestId);
      _logger.d('Generated new guest ID: $guestId');
    }

    return guestId;
  }

  String _generateGuestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'guest_${timestamp}_$random';
  }

  Future<void> clearGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGuestId);
    _logger.d('Guest ID cleared');
  }

  Future<void> printSessionInfo() async {
    final isLogged = await isLoggedIn();
    final token = await getToken();
    final userName = await getUserName();
    final guestId = await getGuestId();

    _logger.d('''
     Session Info:
    - Logged In: $isLogged
    - Token: ${token?.substring(0, 20)}...
    - User Name: $userName
    - Guest ID: $guestId
    ''');
  }

  Future<String> getBearerToken() async {
    final token = await getToken();
    return token != null ? 'Bearer $token' : '';
  }
}