// lib/data/models/category_model.dart

class CategoryResponse {
  final Category category;
  final List<Subcategory> subcategories;

  CategoryResponse({
    required this.category,
    required this.subcategories,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'];
    final subcategoriesJson = json['subcategories'];

    return CategoryResponse(
      category: Category.fromJson(
        categoryJson is Map<String, dynamic> ? categoryJson : const {},
      ),
      subcategories: (subcategoriesJson is List ? subcategoriesJson : const [])
          .whereType<Map<String, dynamic>>()
          .map((item) => Subcategory.fromJson(item))
          .toList(),
    );
  }
}

class Category {
  final int id;
  final String name;
  final String categorySlug;
  final String? image;
  final String? icon;
  final String status;

  Category({
    required this.id,
    required this.name,
    required this.categorySlug,
    this.image,
    this.icon,
    required this.status,
  });

  factory Category.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};

    return Category(
      id: _parseInt(data['id']),
      name: data['name']?.toString() ?? '',
      categorySlug: data['category_slug']?.toString() ?? '',
      image: data['image']?.toString(),
      icon: data['icon']?.toString(),
      status: data['status']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}

class Subcategory {
  final int id;
  final String name;
  final String subcategorySlug;
  final int categoryId;
  final int vat;
  final String? image;
  final String? appImage;
  final String? icon;
  final String status;

  Subcategory({
    required this.id,
    required this.name,
    required this.subcategorySlug,
    required this.categoryId,
    required this.vat,
    this.image,
    this.appImage,
    this.icon,
    required this.status,
  });

  factory Subcategory.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};

    return Subcategory(
      id: _parseInt(data['id']),
      name: data['name']?.toString() ?? '',
      subcategorySlug: data['subcategory_slug']?.toString() ?? '',
      categoryId: _parseInt(data['category_id']),
      vat: _parseInt(data['vat']),
      image: data['image']?.toString(),
      appImage: data['app_image']?.toString(),
      icon: data['icon']?.toString(),
      status: data['status']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}

/// Product Model
class Product {
  final int id;
  final String name;
  final String? image;
  final double salePrice;
  final double? salesPriceWithCharge;
  final double? regularPrice;
  final int subcategoryId;
  final String? shopName;
  final int? shopId;
  final String? weight;
  final String? unitName;
  final int quantity;
  final bool isInWishlist;

  Product({
    required this.id,
    required this.name,
    this.image,
    required this.salePrice,
    this.salesPriceWithCharge,
    this.regularPrice,
    required this.subcategoryId,
    this.shopName,
    this.shopId,
    this.weight,
    this.unitName,
    this.quantity = 0,
    this.isInWishlist = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _parseInt(json['id'] ?? json['shop_product_id']),
      name: json['name'] ?? '',
      image: json['image'],
      salePrice: _parseDouble(json['sale_price']),
      salesPriceWithCharge: _parseDouble(json['sales_price_with_charge']),
      regularPrice: _parseDouble(json['regular_price']),
      subcategoryId: _parseInt(json['subcategory_id']),
      shopName: json['shop_name'],
      shopId: _parseIntNullable(json['shop_id'] ?? json['seller_id']),
      weight: json['weight']?.toString(),
      unitName: json['unit_name'],
      quantity: _parseInt(json['quantity']),
      isInWishlist: _parseBool(json['is_in_wishlist']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'sale_price': salePrice,
      'sales_price_with_charge': salesPriceWithCharge,
      'regular_price': regularPrice,
      'subcategory_id': subcategoryId,
      'shop_name': shopName,
      'shop_id': shopId,
      'weight': weight,
      'unit_name': unitName,
      'quantity': quantity,
      'is_in_wishlist': isInWishlist,
    };
  }

  Product copyWith({
    int? quantity,
    bool? isInWishlist,
  }) {
    return Product(
      id: id,
      name: name,
      image: image,
      salePrice: salePrice,
      salesPriceWithCharge: salesPriceWithCharge,
      regularPrice: regularPrice,
      subcategoryId: subcategoryId,
      shopName: shopName,
      shopId: shopId,
      weight: weight,
      unitName: unitName,
      quantity: quantity ?? this.quantity,
      isInWishlist: isInWishlist ?? this.isInWishlist,
    );
  }
}
