// lib/core/services/notification_handler.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Function(Map<String, dynamic>)? _onNotificationTapped;

  // Initialize local notifications
  Future<void> initialize({
    Function(Map<String, dynamic>)? onNotificationTapped,
  }) async {
    if (_initialized) {
      developer.log('Notifications already initialized', name: 'NotificationHandler');
      return;
    }

    _onNotificationTapped = onNotificationTapped;

    try {
      developer.log('Initializing local notifications...', name: 'NotificationHandler');

      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      _initialized = true;
      developer.log('Local notifications initialized', name: 'NotificationHandler');
    } catch (e) {
      developer.log('Error initializing local notifications: $e', name: 'NotificationHandler');
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'bideshibazar_channel',
      'BideshiBazar Notifications',
      description: 'Order updates and notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    developer.log(' Notification channel created: bideshibazar_channel', name: 'NotificationHandler');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      developer.log(' Showing notification', name: 'NotificationHandler');
      developer.log('   Title: $title', name: 'NotificationHandler');
      developer.log('   Body: $body', name: 'NotificationHandler');

      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'bideshibazar_channel',
        'BideshiBazar Notifications',
        channelDescription: 'Order updates and notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails.copyWith(
          styleInformation: BigTextStyleInformation(body), // BigTextStyle
        ),
        iOS: iosDetails,
      );

      // Use timestamp as unique notification ID (like in Java)
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notifications.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: payload,
      );

      developer.log(' Notification shown successfully (ID: $notificationId)', name: 'NotificationHandler');
    } catch (e) {
      developer.log(' Error showing notification: $e', name: 'NotificationHandler');
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    developer.log('Notification tapped', name: 'NotificationHandler');
    developer.log('Payload: ${response.payload}', name: 'NotificationHandler');

    if (response.payload != null && _onNotificationTapped != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        _onNotificationTapped!(data);
      } catch (e) {
        developer.log('Error parsing notification payload: $e', name: 'NotificationHandler');
      }
    }
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    developer.log('🗑️ All notifications cancelled', name: 'NotificationHandler');
  }

  // Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
    developer.log('🗑️ Notification $id cancelled', name: 'NotificationHandler');
  }
}

// Extension to copy AndroidNotificationDetails with styleInformation
extension AndroidNotificationDetailsExtension on AndroidNotificationDetails {
  AndroidNotificationDetails copyWith({
    StyleInformation? styleInformation,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      showWhen: showWhen,
      enableVibration: enableVibration,
      playSound: playSound,
      autoCancel: autoCancel,
      styleInformation: styleInformation ?? this.styleInformation,
    );
  }
}

