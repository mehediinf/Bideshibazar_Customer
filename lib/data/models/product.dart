import '../../core/network/api_constants.dart';

class Product {
  // IDs
  final String id; // shop_product_id
  int wishlistItemId;
  int cartItemId;

  // Seller Info
  final int sellerId;
  final String vendorName; // shop_name

  // Basic Info
  final String title; // name
  final String description;
  final String shortDescription;
  final String longDescription;

  // Pricing
  final String price; // sales_price_with_charge
  final String oldPrice; // sale_price
  final String finalPrice;

  // Product Details
  final String imageUrl;
  final String weight;
  final String unit; // unit_name

  // Stock & Offers
  final int stock;
  final bool hasOffer;
  final int subcategoryId;

  // State
  int quantity;
  bool isFavorite;

  Product({
    required this.id,
    this.wishlistItemId = 0,
    this.cartItemId = -1,
    required this.sellerId,
    this.vendorName = '',
    required this.title,
    this.description = '',
    this.shortDescription = '',
    this.longDescription = '',
    required this.price,
    this.oldPrice = '',
    this.finalPrice = '',
    required this.imageUrl,
    this.weight = '',
    this.unit = '',
    this.stock = 0,
    this.hasOffer = false,
    this.subcategoryId = -1,
    this.quantity = 0,
    this.isFavorite = false,
  });

  // ========== FROM JSON (Matches Android Logic) ==========
  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle nested "product" object
    Map<String, dynamic> obj = json;
    if (json.containsKey('product') && json['product'] is Map) {
      obj = json['product'] as Map<String, dynamic>;
    }

    return Product(
      id: _parseString(obj['shop_product_id']),
      wishlistItemId: _parseInt(obj['wishlist_item_id']),
      cartItemId: _parseInt(obj['cart_item_id'], defaultValue: -1),
      sellerId: _parseInt(obj['seller_id']),
      vendorName: _parseString(obj['shop_name']),
      title: _parseString(obj['name'], defaultValue: 'Unknown Product'),
      description: _parseString(obj['description']),
      shortDescription: _parseString(obj['short_description']),
      longDescription: _parseString(obj['long_description']),
      price: _parseString(obj['sales_price_with_charge'], defaultValue: '0.0'),
      oldPrice: _parseString(obj['sale_price']),
      finalPrice: _parseString(obj['final_price']),
      imageUrl: _parseImageUrl(obj['image']),
      weight: _parseString(obj['weight']),
      unit: _parseString(obj['unit_name']),
      stock: _parseInt(obj['stock_quantity']),
      hasOffer: _parseBool(obj['has_offer']),
      subcategoryId: _parseInt(obj['subcategory_id'], defaultValue: -1),
      quantity: _parseInt(obj['quantity']),
      isFavorite: _parseBool(obj['is_favorite']),
    );
  }

  // ========== TO JSON ==========
  Map<String, dynamic> toJson() {
    return {
      'shop_product_id': id,
      'wishlist_item_id': wishlistItemId,
      'cart_item_id': cartItemId,
      'seller_id': sellerId,
      'shop_name': vendorName,
      'name': title,
      'description': description,
      'short_description': shortDescription,
      'long_description': longDescription,
      'sales_price_with_charge': price,
      'sale_price': oldPrice,
      'final_price': finalPrice,
      'image': imageUrl,
      'weight': weight,
      'unit_name': unit,
      'stock_quantity': stock,
      'has_offer': hasOffer,
      'subcategory_id': subcategoryId,
      'quantity': quantity,
      'is_favorite': isFavorite,
    };
  }

  // ========== HELPER PARSERS ==========
  static String _parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    return value.toString();
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      try {
        if (value.contains('.')) {
          return double.parse(value).round();
        }
        return int.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  static String _parseImageUrl(dynamic value) {
    if (value == null) return '';
    String url = value.toString().replaceAll('\\', '/');
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConstants.imageBaseUrl}product/$url';
  }

  // ========== DISPLAY METHODS ==========
  String getDisplayPrice() {
    if (hasOffer && finalPrice.isNotEmpty) {
      return finalPrice;
    }
    return price;
  }

  String getDisplayOldPrice() {
    return hasOffer ? price : '';
  }

  double getPriceAsDouble() {
    try {
      String cleanPrice = getDisplayPrice().replaceAll(RegExp(r'[^\d.]'), '');
      return double.parse(cleanPrice);
    } catch (e) {
      return 0.0;
    }
  }

  // ========== QUANTITY METHODS ==========
  Product increaseQuantity() {
    return copyWith(quantity: quantity + 1);
  }

  Product decreaseQuantity() {
    if (quantity > 0) {
      return copyWith(quantity: quantity - 1);
    }
    return this;
  }

  Product setQuantity(int newQuantity) {
    return copyWith(quantity: newQuantity < 0 ? 0 : newQuantity);
  }

  // ========== COPY WITH ==========
  Product copyWith({
    String? id,
    int? wishlistItemId,
    int? cartItemId,
    int? sellerId,
    String? vendorName,
    String? title,
    String? description,
    String? shortDescription,
    String? longDescription,
    String? price,
    String? oldPrice,
    String? finalPrice,
    String? imageUrl,
    String? weight,
    String? unit,
    int? stock,
    bool? hasOffer,
    int? subcategoryId,
    int? quantity,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      wishlistItemId: wishlistItemId ?? this.wishlistItemId,
      cartItemId: cartItemId ?? this.cartItemId,
      sellerId: sellerId ?? this.sellerId,
      vendorName: vendorName ?? this.vendorName,
      title: title ?? this.title,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      hasOffer: hasOffer ?? this.hasOffer,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      quantity: quantity ?? this.quantity,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // ========== EQUALITY ==========
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, title: $title, price: $price, quantity: $quantity)';
  }
}

// ========== BANNER ITEM MODEL ==========
class BannerItem {
  final int id;
  final String imageUrl;
  final String? link;

  BannerItem({
    required this.id,
    required this.imageUrl,
    this.link,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? json['image'] ?? '',
      link: json['link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'link': link,
    };
  }
}

// ========== CATEGORY ITEM MODEL ==========
class CategoryItem {
  final int id;
  final String name;
  final String imageUrl;

  CategoryItem({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    String imgUrl = json['app_image'] ?? json['image'] ?? '';
    if (imgUrl.isNotEmpty && !imgUrl.startsWith('http')) {
      imgUrl = '${ApiConstants.baseUrlWithoutApi}$imgUrl';
    }

    return CategoryItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imageUrl: imgUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': imageUrl,
    };
  }
}