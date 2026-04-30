class ComplaintLookupItem {
  final String key;
  final String label;

  const ComplaintLookupItem({required this.key, required this.label});

  factory ComplaintLookupItem.fromJson(Map<String, dynamic> json) {
    return ComplaintLookupItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class EligibleComplaintOrder {
  final int id;
  final String code;
  final String date;
  final String total;
  final String shop;

  const EligibleComplaintOrder({
    required this.id,
    required this.code,
    required this.date,
    required this.total,
    required this.shop,
  });

  factory EligibleComplaintOrder.fromJson(Map<String, dynamic> json) {
    return EligibleComplaintOrder(
      id: json['id'] as int? ?? int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: json['code']?.toString() ?? 'N/A',
      date: json['date']?.toString() ?? '',
      total: json['total']?.toString() ?? '0.00',
      shop: json['shop']?.toString() ?? 'Unknown shop',
    );
  }
}

class ComplaintHistoryItem {
  final int id;
  final String orderCode;
  final String category;
  final String complaintText;
  final String conditionalDetail;
  final String status;
  final String createdAt;
  final String? replyMessage;
  final String? replyAt;
  final List<String> photos;

  const ComplaintHistoryItem({
    required this.id,
    required this.orderCode,
    required this.category,
    required this.complaintText,
    required this.conditionalDetail,
    required this.status,
    required this.createdAt,
    required this.photos,
    this.replyMessage,
    this.replyAt,
  });

  factory ComplaintHistoryItem.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return fallback;
    }

    List<String> readPhotos() {
      final possible = [json['photos'], json['images'], json['attachments']];

      for (final value in possible) {
        if (value is List) {
          return value
              .map((item) {
                if (item is String) return item;
                if (item is Map<String, dynamic>) {
                  return item['url']?.toString() ??
                      item['path']?.toString() ??
                      '';
                }
                return '';
              })
              .where((item) => item.isNotEmpty)
              .toList();
        }
      }

      return const [];
    }

    final orderMap = json['order'];
    final replyMap = json['latest_reply'];

    return ComplaintHistoryItem(
      id: json['id'] as int? ?? int.tryParse(json['id']?.toString() ?? '') ?? 0,
      orderCode: readString(
        ['order_code'],
        fallback: orderMap is Map<String, dynamic>
            ? orderMap['code']?.toString() ?? 'Order'
            : 'Order',
      ),
      category: readString(['category_label', 'category'], fallback: 'Issue'),
      complaintText: readString([
        'complaint_text',
        'title',
        'message',
        'description',
      ], fallback: 'No complaint details available.'),
      conditionalDetail: readString([
        'conditional_detail',
        'detail',
        'details',
      ]),
      status: readString(['status_label', 'status'], fallback: 'open'),
      createdAt: readString([
        'created_at',
        'date',
      ], fallback: json['updated_at']?.toString() ?? ''),
      replyMessage: replyMap is Map<String, dynamic>
          ? replyMap['message']?.toString()
          : json['reply_message']?.toString(),
      replyAt: replyMap is Map<String, dynamic>
          ? replyMap['created_at']?.toString()
          : json['reply_at']?.toString(),
      photos: readPhotos(),
    );
  }
}
