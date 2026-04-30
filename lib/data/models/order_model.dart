// lib/data/models/order_model.dart

class Order {
  final int id;
  final String uuid;
  final String code;
  final String date;
  final String name;
  final String mobile;
  final String email;
  final String city;
  final String address;
  final String subtotal;
  final String shippingCharge;
  final String discountAmount;
  final String tax;
  final String total;
  final String status;
  final int? sellerId;
  final String shopName;
  final bool isInsideMultipleSellers;

  Order({
    required this.id,
    required this.uuid,
    required this.code,
    required this.date,
    required this.name,
    required this.mobile,
    required this.email,
    required this.city,
    required this.address,
    required this.subtotal,
    required this.shippingCharge,
    required this.discountAmount,
    required this.tax,
    required this.total,
    required this.status,
    this.sellerId,
    required this.shopName,
    required this.isInsideMultipleSellers,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    int? toIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    // Safely determine shop name
    String shopName = 'Unknown Shop';
    try {
      // First check if it's multiple sellers
      final isMultipleSellers = json['is_inside_multiple_sellers'] == 1 ||
          json['is_inside_multiple_sellers'] == true;

      if (isMultipleSellers) {
        shopName = 'Multiple Sellers';
      } else {
        // Check if seller object exists and has shop_name
        if (json['seller'] != null && json['seller'] is Map<String, dynamic>) {
          final seller = json['seller'] as Map<String, dynamic>;
          if (seller['shop_name'] != null && seller['shop_name'].toString().isNotEmpty) {
            shopName = seller['shop_name'].toString();
          } else if (seller['name'] != null && seller['name'].toString().isNotEmpty) {
            // Fallback to seller name if shop_name is not available
            shopName = seller['name'].toString();
          }
        }
      }
    } catch (e) {
      print('Error determining shop name: $e');
    }

    return Order(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid']?.toString() ?? '',
      code: json['code']?.toString() ?? 'N/A',
      date: json['date']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? 'No address',
      subtotal: json['subtotal']?.toString() ?? '0.00',
      shippingCharge: json['shipping_charge']?.toString() ?? '0.00',
      discountAmount: json['discount_amount']?.toString() ?? '0.00',
      tax: json['tax']?.toString() ?? '0.00',
      total: json['total']?.toString() ?? '0.00',
      status: json['status']?.toString() ?? 'unknown',
      sellerId: toIntSafe(json['seller_id']),
      shopName: shopName,
      isInsideMultipleSellers: json['is_inside_multiple_sellers'] == 1 ||
          json['is_inside_multiple_sellers'] == true,
    );
  }

  // Helper method to get formatted date
  String getFormattedDate() {
    try {
      return date;
    } catch (e) {
      return date;
    }
  }

  // Helper method to check if order is cancellable
  bool get isCancellable {
    final cancelableStatuses = ['processing', 'pending', 'payment_pending'];
    return cancelableStatuses.contains(status.toLowerCase());
  }

  @override
  String toString() {
    return 'Order(id: $id, code: $code, status: $status, total: $total, shop: $shopName)';
  }
}