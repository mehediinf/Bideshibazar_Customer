// lib/data/models/order_detail_model.dart

class OrderDetail {
  final int id;
  final String uuid;
  final String orderType;
  final String code;
  final String date;
  final String name;
  final String mobile;
  final String email;
  final String createdAt;
  final String city;
  final String postCode;
  final String address;
  final String lat;
  final String lon;
  final String subtotal;
  final String shippingCharge;
  final String discountAmount;
  final String tax;
  String total;
  final String totalWholesalePrice;
  final bool isDeliveryChargeFree;
  final String internalStatus;
  final String status;
  final int? sellerId;
  final String shopName;
  final String orderRegion;
  final String orderNote;
  final String deliveryType;
  final String deliveryPartner;
  final String deliveryPartnerLogo;
  final String approxDeliveryTime;
  final String woltOrderId;
  final String trackingId;
  final String trackingUrl;
  final String invoiceUrl;
  List<OrderItem> orderItems;

  OrderDetail({
    required this.id,
    required this.uuid,
    required this.orderType,
    required this.code,
    required this.date,
    required this.name,
    required this.mobile,
    required this.email,
    required this.createdAt,
    required this.city,
    required this.postCode,
    required this.address,
    required this.lat,
    required this.lon,
    required this.subtotal,
    required this.shippingCharge,
    required this.discountAmount,
    required this.tax,
    required this.total,
    required this.totalWholesalePrice,
    required this.isDeliveryChargeFree,
    required this.internalStatus,
    required this.status,
    this.sellerId,
    required this.shopName,
    required this.orderRegion,
    required this.orderNote,
    required this.deliveryType,
    required this.deliveryPartner,
    required this.deliveryPartnerLogo,
    required this.approxDeliveryTime,
    required this.woltOrderId,
    required this.trackingId,
    required this.trackingUrl,
    required this.invoiceUrl,
    required this.orderItems,
  });

  String get effectiveStatus =>
      internalStatus.isNotEmpty ? internalStatus : status;

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    var shopName = 'Unknown Shop';

    if (json['seller'] is Map<String, dynamic>) {
      final seller = json['seller'] as Map<String, dynamic>;
      shopName = _toString(seller['shop_name']).isNotEmpty
          ? _toString(seller['shop_name'])
          : _toString(seller['name'], fallback: shopName);
    }

    final rawItems = json['order_items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(OrderItem.fromJson)
              .toList()
        : <OrderItem>[];

    return OrderDetail(
      id: _toInt(json['id']),
      uuid: _toString(json['uuid']),
      orderType: _toString(json['order_type']),
      code: _toString(json['code'], fallback: 'N/A'),
      date: _toString(json['date']),
      name: _toString(json['name']),
      mobile: _toString(json['mobile']),
      email: _toString(json['email']),
      createdAt: _toString(json['created_at']),
      city: _toString(json['city']),
      postCode: _toString(json['post_code']),
      address: _toString(json['address'], fallback: 'No address'),
      lat: _toString(json['lat']),
      lon: _toString(json['lon']),
      subtotal: _toMoney(json['subtotal']),
      shippingCharge: _toMoney(json['shipping_charge']),
      discountAmount: _toMoney(json['discount_amount']),
      tax: _toMoney(json['tax']),
      total: _toMoney(json['total']),
      totalWholesalePrice: _toMoney(json['total_wholesale_price']),
      isDeliveryChargeFree: _toBool(json['is_delivery_charge_free']),
      internalStatus: _toString(
        json['internal_status'],
        fallback: _toString(json['status'], fallback: 'unknown'),
      ),
      status: _toString(json['status'], fallback: 'unknown'),
      sellerId: _toNullableInt(json['seller_id']),
      shopName: shopName,
      orderRegion: _toString(json['order_region']),
      orderNote: _toString(json['order_note']),
      deliveryType: _toString(json['delivery_type']),
      deliveryPartner: _toString(json['delivery_partner']),
      deliveryPartnerLogo: _toString(json['delivery_partner_logo']),
      approxDeliveryTime: _toString(json['approx_delivery_time']),
      woltOrderId: _toString(json['wolt_order_id']),
      trackingId: _toString(json['tracking_id']),
      trackingUrl: _toString(json['tracking_url']),
      invoiceUrl: _toString(json['invoice_url']),
      orderItems: items,
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  int quantity;
  final String wholesalePrice;
  final String salePrice;
  final String subtotal;
  final String weight;
  final bool isAvailable;
  final bool isReplaced;
  final OrderReplacement? replacement;
  final Product product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.wholesalePrice,
    required this.salePrice,
    required this.subtotal,
    required this.weight,
    required this.isAvailable,
    required this.isReplaced,
    required this.replacement,
    required this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map<String, dynamic>
        ? Product.fromJson(json['product'] as Map<String, dynamic>)
        : Product.empty();
    final replacementJson = _findReplacementJson(json);

    return OrderItem(
      id: _toInt(json['id']),
      orderId: _toInt(json['order_id']),
      productId: _toInt(json['product_id'], fallback: product.id),
      quantity: _toInt(json['quantity'], fallback: 1),
      wholesalePrice: _toMoney(json['wholesale_price']),
      salePrice: _toMoney(json['sale_price']),
      subtotal: _toMoney(
        json['subtotal'],
        fallback: _lineTotal(json['quantity'], json['sale_price']),
      ),
      weight: _toString(
        json['weight'],
        fallback: product.weight.isNotEmpty ? product.weight : product.unit,
      ),
      isAvailable: _toBool(json['is_available'], fallback: true),
      isReplaced: _toBool(json['is_replaced']),
      replacement: replacementJson != null
          ? OrderReplacement.fromJson(replacementJson)
          : null,
      product: product,
    );
  }
}

class OrderReplacement {
  final int id;
  final int quantity;
  final String wholesalePrice;
  final String salePrice;
  final Product product;

  OrderReplacement({
    required this.id,
    required this.quantity,
    required this.wholesalePrice,
    required this.salePrice,
    required this.product,
  });

  factory OrderReplacement.fromJson(Map<String, dynamic> json) {
    return OrderReplacement(
      id: _toInt(json['id']),
      quantity: _toInt(json['quantity'], fallback: 1),
      wholesalePrice: _toMoney(json['wholesale_price']),
      salePrice: _toMoney(json['sale_price']),
      product: json['product'] is Map<String, dynamic>
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : Product.empty(),
    );
  }
}

class Product {
  final int id;
  final String salePrice;
  final String salesPriceWithCharge;
  final String weight;
  final ProductDetail productDetail;

  Product({
    required this.id,
    required this.salePrice,
    required this.salesPriceWithCharge,
    required this.weight,
    required this.productDetail,
  });

  String get name => productDetail.name;
  String get image => productDetail.image;
  String get unit => productDetail.unit;
  bool get isWeightRequired => productDetail.isWeightRequired;
  String get weightRandomNumber => productDetail.weightRandomNumber;

  factory Product.fromJson(Map<String, dynamic> json) {
    final nestedProduct = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : json;

    return Product(
      id: _toInt(json['id'], fallback: _toInt(nestedProduct['id'])),
      salePrice: _toMoney(json['sale_price']),
      salesPriceWithCharge: _toMoney(
        json['sales_price_with_charge'],
        fallback: _toMoney(json['sale_price']),
      ),
      weight: _toString(
        json['weight'],
        fallback: _toString(nestedProduct['unit']),
      ),
      productDetail: ProductDetail.fromJson(nestedProduct),
    );
  }

  factory Product.empty() {
    return Product(
      id: 0,
      salePrice: '0.00',
      salesPriceWithCharge: '0.00',
      weight: '',
      productDetail: ProductDetail.empty(),
    );
  }
}

class ProductDetail {
  final int id;
  final String name;
  final String image;
  final String weight;
  final String unit;
  final bool isWeightRequired;
  final String weightRandomNumber;

  ProductDetail({
    required this.id,
    required this.name,
    required this.image,
    required this.weight,
    required this.unit,
    required this.isWeightRequired,
    required this.weightRandomNumber,
  });

  String get displayUnit {
    if (unit.isNotEmpty) return unit;
    if (weightRandomNumber.isNotEmpty) return weightRandomNumber;
    if (weight.isNotEmpty && weight != '0') return weight;
    return 'Unit not specified';
  }

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: _toInt(json['id']),
      name: _toString(json['name'], fallback: 'Unknown Product'),
      image: _toString(json['image']),
      weight: _toString(json['weight']),
      unit: _toString(json['unit']),
      isWeightRequired: _toBool(json['is_weight_required']),
      weightRandomNumber: _toString(json['weight_random_number']),
    );
  }

  factory ProductDetail.empty() {
    return ProductDetail(
      id: 0,
      name: 'Unknown Product',
      image: '',
      weight: '',
      unit: '',
      isWeightRequired: false,
      weightRandomNumber: '',
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  }
  return fallback;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  return _toInt(value);
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

String _toString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final stringValue = value.toString().trim();
  return stringValue.isEmpty ? fallback : stringValue;
}

String _toMoney(dynamic value, {String fallback = '0.00'}) {
  final stringValue = _toString(value, fallback: fallback);
  return stringValue.isEmpty ? fallback : stringValue;
}

String _lineTotal(dynamic quantity, dynamic salePrice) {
  final qty = _toInt(quantity, fallback: 1);
  final price = double.tryParse(_toString(salePrice, fallback: '0')) ?? 0;
  return (qty * price).toStringAsFixed(2);
}

Map<String, dynamic>? _findReplacementJson(Map<String, dynamic> json) {
  const candidateKeys = [
    'replacement',
    'replace_product',
    'replacement_product',
    'replaced_product',
    'replaceProduct',
    'replacementProduct',
  ];

  for (final key in candidateKeys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
  }

  return null;
}
