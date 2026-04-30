import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/notification_item.dart';
import 'dart:developer' as developer;

class NotificationService {
  final String baseUrl;
  final String? token;

  NotificationService({
    required this.baseUrl,
    this.token,
  });

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final url = '${baseUrl}user/notifications';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notificationsJson = data['notifications'] ?? [];
        final int unreadCount = data['unread_notification_count'] ?? 0;

        final notifications = notificationsJson
            .map((json) => NotificationItem.fromJson(json))
            .toList();

        return {
          'notifications': notifications,
          'unread_count': unreadCount,
        };
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      final url = '${baseUrl}user/notifications/mark-as-read/$notificationId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'unread_count': data['unread_notification_count'] ?? 0,
        };
      } else {
        throw Exception('Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Mark as Read Error: $e', name: 'NotificationService');
      throw Exception('Network error: $e');
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final url = '${baseUrl}user/notifications/mark-all-as-read';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        developer.log('Mark All as Read Failed: ${response.statusCode}', name: 'NotificationService');
        return false;
      }
    } catch (e) {
      developer.log('Mark All as Read Error: $e', name: 'NotificationService');
      throw Exception('Network error: $e');
    }
  }
}