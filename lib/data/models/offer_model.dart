// lib/data/models/offer_model.dart

class OfferModel {
  final int id;
  final String offerName;
  final String sellerName;
  final int? sellerId;
  final String image;
  final String discountType;
  final String discountValue;
  final List<ProductModel> products;

  OfferModel({
    required this.id,
    required this.offerName,
    required this.sellerName,
    this.sellerId,
    required this.image,
    required this.discountType,
    required this.discountValue,
    required this.products,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] ?? 0,
      offerName: json['offer_name'] ?? '',
      sellerName: json['seller_name'] ?? '',
      sellerId: json['seller_id'] is int
          ? json['seller_id']
          : int.tryParse(json['seller_id']?.toString() ?? '0'),
      image: json['image'] ?? '',
      discountType: json['discount_type'] ?? '',
      discountValue: json['discount_value'] ?? '0',
      products: (json['products'] as List<dynamic>?)
          ?.map((p) => ProductModel.fromJson(p))
          .toList() ??
          [],
    );
  }
}

class ProductModel {
  final int id;
  final String name;
  final String image;
  final String originalPrice;
  final double discountedPrice;
  final String shortDescription;
  final String longDescription;
  final String categoryName;
  final String unitName;
  final String? weight;
  final int? sellerId;

  ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.originalPrice,
    required this.discountedPrice,
    required this.shortDescription,
    required this.longDescription,
    required this.categoryName,
    required this.unitName,
    this.weight,
    this.sellerId,
  });

  // Use id as shopProductId (getter instead of field)
  int get shopProductId => id;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // API returns only 'id', which is the product/shop_product_id we need
    final int productId = json['id'] is int
        ? json['id']
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    return ProductModel(
      id: productId,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      originalPrice: json['original_price']?.toString() ?? '0',
      discountedPrice: json['discounted_price'] is double
          ? json['discounted_price']
          : double.tryParse(json['discounted_price']?.toString() ?? '0') ?? 0.0,
      shortDescription: json['short_description'] ?? '',
      longDescription: json['long_description'] ?? '',
      categoryName: json['category_name'] ?? '',
      unitName: json['unit_name'] ?? '',
      weight: json['weight']?.toString() ?? '1',
      sellerId: json['seller_id'] != null
          ? (json['seller_id'] is int
          ? json['seller_id']
          : int.tryParse(json['seller_id'].toString()))
          : null,
    );
  }
}

class OfferResponse {
  final bool success;
  final List<OfferModel> offers;

  OfferResponse({
    required this.success,
    required this.offers,
  });

  factory OfferResponse.fromJson(Map<String, dynamic> json) {
    return OfferResponse(
      success: json['success'] ?? false,
      offers: (json['offers'] as List<dynamic>?)
          ?.map((o) => OfferModel.fromJson(o))
          .toList() ??
          [],
    );
  }
}