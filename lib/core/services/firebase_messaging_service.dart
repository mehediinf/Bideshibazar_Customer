// lib/core/services/firebase_messaging_service.dart

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;
import 'notification_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/shared_prefs_helper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final NotificationHandler _notificationHandler = NotificationHandler();
  final StreamController<Map<String, dynamic>> _orderRefreshController =
      StreamController<Map<String, dynamic>>.broadcast();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Stream<Map<String, dynamic>> get orderRefreshStream =>
      _orderRefreshController.stream;

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      //  Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        developer.log(' Firebase not initialized!', name: 'FCM_INIT');
        developer.log('   Please initialize Firebase first', name: 'FCM_INIT');
        return;
      }

      developer.log(' Firebase is ready', name: 'FCM_INIT');

      _firebaseMessaging = FirebaseMessaging.instance;
      developer.log(' FirebaseMessaging instance created', name: 'FCM_INIT');

      await _requestPermission();

      // Initialize local notifications
      try {
        await _notificationHandler.initialize(
          onNotificationTapped: _handleNotificationTap,
        );
        developer.log('Local notifications initialized', name: 'FCM_INIT');
      } catch (e) {
        developer.log('Local notification init failed: $e', name: 'FCM_INIT');
      }

      // Get FCM token
      await _getToken();

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
    } catch (e, stackTrace) {
      developer.log(' CRITICAL ERROR in FCM initialization', name: 'FCM_INIT');
      developer.log('   Error: $e', name: 'FCM_INIT');
      developer.log('   Stack: $stackTrace', name: 'FCM_INIT');
    }
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    try {
      if (_firebaseMessaging == null) {
        developer.log(' FirebaseMessaging is NULL', name: 'FCM_PERMISSION');
        return;
      }

      NotificationSettings settings = await _firebaseMessaging!
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log(
          ' Notification permission GRANTED',
          name: 'FCM_PERMISSION',
        );
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        developer.log(
          ' Provisional permission granted',
          name: 'FCM_PERMISSION',
        );
      } else {
        developer.log(
          ' Notification permission DENIED',
          name: 'FCM_PERMISSION',
        );
      }
    } catch (e) {
      developer.log(' Permission request error: $e', name: 'FCM_PERMISSION');
    }
  }

  // Get FCM token
  Future<String?> _getToken() async {
    try {
      if (_firebaseMessaging == null) {
        developer.log(
          ' FirebaseMessaging is NULL, cannot get token',
          name: 'FCM_TOKEN',
        );
        return null;
      }

      // Try multiple times with delay
      for (int attempt = 1; attempt <= 3; attempt++) {
        developer.log('   Attempt $attempt/3', name: 'FCM_TOKEN');

        _fcmToken = await _firebaseMessaging!.getToken();

        if (_fcmToken != null && _fcmToken!.isNotEmpty) {
          developer.log(
            ' FCM Token retrieved successfully!',
            name: 'FCM_TOKEN',
          );
          developer.log(
            '   Length: ${_fcmToken!.length} characters',
            name: 'FCM_TOKEN',
          );
          developer.log(
            '   Preview: ${_fcmToken!.substring(0, 30)}...',
            name: 'FCM_TOKEN',
          );
          developer.log('   Full Token:', name: 'FCM_TOKEN');
          developer.log(_fcmToken!, name: 'FCM_TOKEN');

          // Save token locally
          await _saveTokenLocally(_fcmToken!);

          break;
        } else {
          developer.log(' Token NULL on attempt $attempt', name: 'FCM_TOKEN');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: attempt));
          }
        }
      }

      if (_fcmToken == null) {
        developer.log(
          ' Failed to get FCM token after 3 attempts',
          name: 'FCM_TOKEN',
        );
        return null;
      }

      // Listen for token refresh
      _firebaseMessaging!.onTokenRefresh.listen((newToken) {
        developer.log(' FCM Token refreshed!', name: 'FCM_TOKEN');
        developer.log(
          '   New token: ${newToken.substring(0, 30)}...',
          name: 'FCM_TOKEN',
        );
        _fcmToken = newToken;
        _saveTokenLocally(newToken);
        _autoSendTokenToBackend(newToken);
      });

      return _fcmToken;
    } catch (e, stackTrace) {
      developer.log(' Error getting FCM token', name: 'FCM_TOKEN');
      developer.log('   Error: $e', name: 'FCM_TOKEN');
      developer.log('   Stack: $stackTrace', name: 'FCM_TOKEN');
      return null;
    }
  }

  // Save token locally
  Future<void> _saveTokenLocally(String token) async {
    try {
      await SharedPrefsHelper.saveFcmToken(token);
      developer.log(' FCM token saved to SharedPreferences', name: 'FCM_TOKEN');
    } catch (e) {
      developer.log(' Error saving token: $e', name: 'FCM_TOKEN');
    }
  }

  // Auto-send token to backend when refreshed
  Future<void> _autoSendTokenToBackend(String token) async {
    try {
      final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
      if (isLoggedIn) {
        final baseUrl = await SharedPrefsHelper.getBaseUrl();
        final authToken = await SharedPrefsHelper.getAuthToken();

        if (baseUrl != null && authToken != null) {
          developer.log('Auto-sending refreshed token...', name: 'FCM_TOKEN');
          await sendTokenToBackend(baseUrl, authToken);
        }
      }
    } catch (e) {
      developer.log('Auto-send failed: $e', name: 'FCM_TOKEN');
    }
  }

  // Setup message handlers
  void _setupMessageHandlers() {
    if (_firebaseMessaging == null) {
      developer.log(
        'Cannot setup handlers - FirebaseMessaging is NULL',
        name: 'FCM_HANDLERS',
      );
      return;
    }

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Foreground message received', name: 'FCM_MESSAGE');

      String title = 'BideshiBazar';
      String body = 'New Notification';

      if (message.notification != null) {
        title = message.notification!.title ?? title;
        body = message.notification!.body ?? body;
      }

      final Map<String, dynamic> data = message.data;
      developer.log('   Title: $title', name: 'FCM_MESSAGE');
      developer.log('   Body: $body', name: 'FCM_MESSAGE');
      developer.log('   Data: $data', name: 'FCM_MESSAGE');

      _emitOrderRefreshIfNeeded(data);
      _showNotification(title, body, data);
    });

    // Background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(' Background message opened', name: 'FCM_MESSAGE');
      _emitOrderRefreshIfNeeded(message.data);
      _handleNotificationTap(message.data);
    });

    // Terminated state
    _handleTerminatedState();

    developer.log(' Message handlers setup complete', name: 'FCM_HANDLERS');
  }

  // Show notification
  Future<void> _showNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      await _notificationHandler.showNotification(
        title: title,
        body: body,
        payload: json.encode(data),
      );
      developer.log(' Notification shown', name: 'FCM_NOTIFICATION');
    } catch (e) {
      developer.log(' Show notification error: $e', name: 'FCM_NOTIFICATION');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> data) {
    developer.log(' Notification tapped', name: 'FCM_TAP');
    developer.log('   Data: $data', name: 'FCM_TAP');
    _emitOrderRefreshIfNeeded(data);

    final context = navigatorKey.currentContext;
    if (context == null) {
      developer.log(' Navigator context is null', name: 'FCM_TAP');
      return;
    }

    final String? clickAction = data['click_action'];
    final String? orderId = data['order_id'];

    if (clickAction == 'PUSH_NOTIFICATION_CLICK') {
      Navigator.of(
        context,
      ).pushNamed('/order-history', arguments: {'order_id': orderId});
    } else {
      Navigator.of(context).pushNamed('/notifications', arguments: data);
    }
  }

  // Handle terminated state
  Future<void> _handleTerminatedState() async {
    if (_firebaseMessaging == null) return;

    RemoteMessage? initialMessage = await _firebaseMessaging!
        .getInitialMessage();
    if (initialMessage != null) {
      developer.log(' App opened from terminated state', name: 'FCM_MESSAGE');
      _emitOrderRefreshIfNeeded(initialMessage.data);
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  void _emitOrderRefreshIfNeeded(Map<String, dynamic> data) {
    if (!_isOrderRelatedNotification(data) ||
        _orderRefreshController.isClosed) {
      return;
    }

    developer.log(' Emitting order refresh event', name: 'FCM_ORDER_REFRESH');
    developer.log('   Payload: $data', name: 'FCM_ORDER_REFRESH');
    _orderRefreshController.add(Map<String, dynamic>.from(data));
  }

  bool _isOrderRelatedNotification(Map<String, dynamic> data) {
    final clickAction = data['click_action']?.toString().toUpperCase();
    final orderId = data['order_id']?.toString();
    final type = data['type']?.toString().toLowerCase();
    final category = data['category']?.toString().toLowerCase();
    final screen = data['screen']?.toString().toLowerCase();

    return (orderId != null && orderId.isNotEmpty) ||
        clickAction == 'PUSH_NOTIFICATION_CLICK' ||
        type == 'order' ||
        category == 'order' ||
        screen == 'order-history';
  }

  // Send token to backend
  Future<void> sendTokenToBackend(String baseUrl, String authToken) async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      developer.log(' No FCM token to send', name: 'FCM_BACKEND');
      return;
    }

    try {
      developer.log(
        '   Token: ${_fcmToken!.substring(0, 30)}...',
        name: 'FCM_BACKEND',
      );

      final response = await http.post(
        Uri.parse('${baseUrl}api/user/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'fcm_token': _fcmToken}),
      );

      if (response.statusCode == 200) {
        developer.log(' FCM token saved to backend!', name: 'FCM_BACKEND');
      } else {
        developer.log(
          ' Backend returned error: ${response.statusCode}',
          name: 'FCM_BACKEND',
        );
      }
    } catch (e, stackTrace) {
      developer.log(' Error sending token to backend', name: 'FCM_BACKEND');
      developer.log('   Error: $e', name: 'FCM_BACKEND');
      developer.log('   Stack: $stackTrace', name: 'FCM_BACKEND');
    }
  }

  // Delete token
  Future<void> deleteToken() async {
    try {
      if (_firebaseMessaging != null) {
        await _firebaseMessaging!.deleteToken();
      }
      await SharedPrefsHelper.clearFcmToken();
      _fcmToken = null;
      developer.log(' FCM token deleted', name: 'FCM_TOKEN');
    } catch (e) {
      developer.log(' Delete token error: $e', name: 'FCM_TOKEN');
    }
  }

  // Get current token
  Future<String?> getCurrentToken() async {
    developer.log(' Getting current FCM token...', name: 'FCM_GET_TOKEN');

    // Return cached token if available
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      developer.log(' Returning cached token', name: 'FCM_GET_TOKEN');
      developer.log('   Length: ${_fcmToken!.length}', name: 'FCM_GET_TOKEN');
      return _fcmToken;
    }

    // Try SharedPreferences
    final savedToken = await SharedPrefsHelper.getFcmToken();
    if (savedToken != null && savedToken.isNotEmpty) {
      developer.log(' Found token in SharedPreferences', name: 'FCM_GET_TOKEN');
      _fcmToken = savedToken;
      return _fcmToken;
    }

    // Get new token from Firebase
    if (_firebaseMessaging != null) {
      developer.log(
        ' Fetching new token from Firebase...',
        name: 'FCM_GET_TOKEN',
      );
      return await _getToken();
    }

    developer.log(
      'Cannot get token - FirebaseMessaging is NULL',
      name: 'FCM_GET_TOKEN',
    );
    return null;
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('Background message (terminated)', name: 'FCM_BACKGROUND');
  developer.log(
    '   Title: ${message.notification?.title}',
    name: 'FCM_BACKGROUND',
  );
  developer.log(
    '   Body: ${message.notification?.body}',
    name: 'FCM_BACKGROUND',
  );
}
