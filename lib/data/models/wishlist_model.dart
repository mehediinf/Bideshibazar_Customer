// lib/data/models/wishlist_model.dart

class WishlistItem {
  final int id;
  final String userId;
  final String productId;
  final String createdAt;
  final String updatedAt;
  final ShopProduct shopProduct;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    required this.shopProduct,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      shopProduct: ShopProduct.fromJson(json['shop_product'] ?? {}),
    );
  }
}

class ShopProduct {
  final int id;
  final String sellerId;
  final String productId;
  final String salePrice;
  final String salesPriceWithCharge;
  final String? discountAmount;
  final String? weight;
  final String productName;
  final String productImage;
  final Product? product;

  ShopProduct({
    required this.id,
    required this.sellerId,
    required this.productId,
    required this.salePrice,
    required this.salesPriceWithCharge,
    this.discountAmount,
    this.weight,
    required this.productName,
    required this.productImage,
    this.product,
  });

  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    return ShopProduct(
      id: json['id'] ?? 0,
      sellerId: json['seller_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      salePrice: json['sale_price']?.toString() ?? '0.00',
      salesPriceWithCharge: json['sales_price_with_charge']?.toString() ?? '0.00',
      discountAmount: json['discount_amount']?.toString(),
      weight: json['weight']?.toString(),
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
    );
  }
}

class Product {
  final int id;
  final String name;
  final String image;
  final String weightQuantity;
  final String weightUnit;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.weightQuantity,
    required this.weightUnit,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      weightQuantity: json['weight_quantity']?.toString() ?? '1.00',
      weightUnit: json['weight_unit'] ?? 'kg',
    );
  }
}

class WishlistResponse {
  final String message;
  final List<WishlistItem> wishlistItems;
  final int wishlistCount;

  WishlistResponse({
    required this.message,
    required this.wishlistItems,
    required this.wishlistCount,
  });

  factory WishlistResponse.fromJson(Map<String, dynamic> json) {
    return WishlistResponse(
      message: json['message'] ?? '',
      wishlistItems: (json['wishlistItems'] as List<dynamic>?)
          ?.map((item) => WishlistItem.fromJson(item))
          .toList() ??
          [],
      wishlistCount: json['wishlistCount'] ?? 0,
    );
  }
}