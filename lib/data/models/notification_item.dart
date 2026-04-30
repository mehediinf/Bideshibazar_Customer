//lib/data/models/notification_item.dart

class NotificationItem {
  final int id;
  final String type;
  final String message;
  final String timeAgo;
  bool isRead;
  bool isExpanded;

  NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    required this.timeAgo,
    required this.isRead,
    this.isExpanded = false,
  });

  // Title from message (first 50 chars or less)
  String get title {
    if (message.isEmpty) {
      return "Notification";
    }
    return message.length > 50 ? '${message.substring(0, 50)}...' : message;
  }

  // Full text is the complete message
  String get fullText => message;

  String get time => timeAgo;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      timeAgo: json['time_ago'] ?? '',
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'time_ago': timeAgo,
      'is_read': isRead,
    };
  }

  NotificationItem copyWith({
    int? id,
    String? type,
    String? message,
    String? timeAgo,
    bool? isRead,
    bool? isExpanded,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      isRead: isRead ?? this.isRead,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

