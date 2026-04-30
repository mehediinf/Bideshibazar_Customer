// lib/data/models/checkout_model.dart

class VerifyAddressResponse {
  final bool success;
  final String message;
  final List<CartItem> cartItems;
  final double deliveryCharge;
  final bool isMultipleStores;
  final bool isDeliveryChargeFree;
  final String deliveryPartner;
  final String deliveryPartnerLogo;
  final String approxDeliveryTime;

  VerifyAddressResponse({
    required this.success,
    required this.message,
    required this.cartItems,
    required this.deliveryCharge,
    required this.isMultipleStores,
    required this.isDeliveryChargeFree,
    required this.deliveryPartner,
    required this.deliveryPartnerLogo,
    required this.approxDeliveryTime,
  });

  factory VerifyAddressResponse.fromJson(Map<String, dynamic> json) {
    // ✅ Handle delivery_charge as both int and double
    final deliveryChargeValue = json['delivery_charge'];
    final double parsedDeliveryCharge = deliveryChargeValue is int
        ? deliveryChargeValue.toDouble()
        : (deliveryChargeValue is double ? deliveryChargeValue : 0.0);

    return VerifyAddressResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      cartItems: (json['cartItems'] as List?)?.map((item) => CartItem.fromJson(item)).toList() ?? [],
      deliveryCharge: parsedDeliveryCharge,  // ✅ Fixed line
      isMultipleStores: json['isMultipleStores'] ?? false,
      isDeliveryChargeFree: json['is_delivery_charge_free'] ?? false,
      deliveryPartner: json['delivery_partner'] ?? '',
      deliveryPartnerLogo: json['delivery_partner_logo'] ?? '',
      approxDeliveryTime: json['approx_delivery_time'] ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'cartItems': cartItems.map((item) => item.toJson()).toList(),
      'delivery_charge': deliveryCharge,
      'isMultipleStores': isMultipleStores,
      'is_delivery_charge_free': isDeliveryChargeFree,
      'delivery_partner': deliveryPartner,
      'delivery_partner_logo': deliveryPartnerLogo,
      'approx_delivery_time': approxDeliveryTime,
    };
  }
}

class CartItem {
  final int id;
  final int productId;
  final int? customItemId;
  final int? varientId;
  final double quantity;
  final int disabled;
  final double wholesalePrice;
  final double price;
  final double? discount;
  final double weight;
  final int customerId;
  final int sellerId;
  final String? guestId;
  final int? shipmentPromiseId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  CartItem({
    required this.id,
    required this.productId,
    this.customItemId,
    this.varientId,
    required this.quantity,
    required this.disabled,
    required this.wholesalePrice,
    required this.price,
    this.discount,
    required this.weight,
    required this.customerId,
    required this.sellerId,
    this.guestId,
    this.shipmentPromiseId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: _parseInt(json['id']),
      productId: _parseInt(json['product_id']),
      customItemId: json['custom_item_id'] != null ? _parseInt(json['custom_item_id']) : null,
      varientId: json['varient_id'] != null ? _parseInt(json['varient_id']) : null,
      quantity: _parseDouble(json['quantity']),
      disabled: _parseInt(json['disabled']),
      wholesalePrice: _parseDouble(json['wholesale_price']),
      price: _parseDouble(json['price']),
      discount: json['discount'] != null ? _parseDouble(json['discount']) : null,
      weight: _parseDouble(json['weight']),
      customerId: _parseInt(json['customer_id']),
      sellerId: _parseInt(json['seller_id']),
      guestId: json['guest_id'],
      shipmentPromiseId: json['shipment_promise_id'] != null ? _parseInt(json['shipment_promise_id']) : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
    );
  }

  // Add this helper method
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'custom_item_id': customItemId,
      'varient_id': varientId,
      'quantity': quantity,
      'disabled': disabled,
      'wholesale_price': wholesalePrice,
      'price': price,
      'discount': discount,
      'weight': weight,
      'customer_id': customerId,
      'seller_id': sellerId,
      'guest_id': guestId,
      'shipment_promise_id': shipmentPromiseId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }
}

// Place Order Response Model
class PlaceOrderResponse {
  final bool success;
  final String message;
  final OrderData? orderData;

  PlaceOrderResponse({
    required this.success,
    required this.message,
    this.orderData,
  });

  factory PlaceOrderResponse.fromJson(Map<String, dynamic> json) {
    return PlaceOrderResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      orderData: json['order'] != null
          ? OrderData.fromJson(json['order'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'order': orderData?.toJson(),
    };
  }
}

class OrderData {
  final int? id;
  final String? orderNumber;
  final double? total;
  final String? status;

  OrderData({
    this.id,
    this.orderNumber,
    this.total,
    this.status,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      id: json['id'],
      orderNumber: json['order_number'],
      total: json['total'] != null
          ? (json['total'] is String
          ? double.tryParse(json['total'])
          : (json['total'] as num).toDouble())
          : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'total': total,
      'status': status,
    };
  }
}