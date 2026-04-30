// lib/data/models/cart_model.dart

class CartItemModel {
  final int id;
  final int productId;
  final int sellerId;
  final String quantity;
  final String wholesalePrice;
  final String price;
  final String? discount;
  final String weight;
  final ShopProductModel? shopProduct;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.quantity,
    required this.wholesalePrice,
    required this.price,
    this.discount,
    required this.weight,
    this.shopProduct,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      quantity: json['quantity']?.toString() ?? '0',
      wholesalePrice: json['wholesale_price']?.toString() ?? '0',
      price: json['price']?.toString() ?? '0',
      discount: json['discount']?.toString(),
      weight: json['weight']?.toString() ?? '0',
      shopProduct: json['shop_product'] != null
          ? ShopProductModel.fromJson(json['shop_product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'seller_id': sellerId,
      'quantity': quantity,
      'wholesale_price': wholesalePrice,
      'price': price,
      'discount': discount,
      'weight': weight,
      'shop_product': shopProduct?.toJson(),
    };
  }

  double get quantityDouble => double.tryParse(quantity) ?? 0.0;
  double get priceDouble => double.tryParse(price) ?? 0.0;
  double get totalPrice => quantityDouble * priceDouble;

  String get productName => shopProduct?.product?.name ?? 'Unknown Product';
  String get productImage => shopProduct?.product?.image ?? '';
  String get unitName => shopProduct?.product?.unit?.name ?? '';
}

class ShopProductModel {
  final int id;
  final int sellerId;
  final int productId;
  final String salePrice;
  final String salesPriceWithCharge;
  final String? discountAmount;
  final String weight;
  final ProductModel? product;

  ShopProductModel({
    required this.id,
    required this.sellerId,
    required this.productId,
    required this.salePrice,
    required this.salesPriceWithCharge,
    this.discountAmount,
    required this.weight,
    this.product,
  });

  factory ShopProductModel.fromJson(Map<String, dynamic> json) {
    return ShopProductModel(
      id: json['id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      salePrice: json['sale_price']?.toString() ?? '0',
      salesPriceWithCharge: json['sales_price_with_charge']?.toString() ?? '0',
      discountAmount: json['discount_amount']?.toString(),
      weight: json['weight']?.toString() ?? '0',
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'product_id': productId,
      'sale_price': salePrice,
      'sales_price_with_charge': salesPriceWithCharge,
      'discount_amount': discountAmount,
      'weight': weight,
      'product': product?.toJson(),
    };
  }
}

class ProductModel {
  final int id;
  final String name;
  final String? image;
  final String productSlug;
  final UnitModel? unit;

  ProductModel({
    required this.id,
    required this.name,
    this.image,
    required this.productSlug,
    this.unit,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
      productSlug: json['product_slug'] ?? '',
      unit: json['unit'] != null
          ? UnitModel.fromJson(json['unit'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'product_slug': productSlug,
      'unit': unit?.toJson(),
    };
  }
}

class UnitModel {
  final int id;
  final String name;
  final String unitSlug;

  UnitModel({
    required this.id,
    required this.name,
    required this.unitSlug,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      unitSlug: json['unit_slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit_slug': unitSlug,
    };
  }
}

class CartResponseModel {
  final List<CartItemModel> cartItems;
  final int total;
  final double? cartTotal;
  final int? cartCount;
  final String? message;

  CartResponseModel({
    required this.cartItems,
    required this.total,
    this.cartTotal,
    this.cartCount,
    this.message,
  });

  factory CartResponseModel.fromJson(Map<String, dynamic> json) {
    return CartResponseModel(
      cartItems: (json['cartItems'] as List?)
          ?.map((item) => CartItemModel.fromJson(item))
          .toList() ??
          [],
      total: json['total'] ?? 0,
      cartTotal: json['cartTotal']?.toDouble(),
      cartCount: json['cartCount'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartItems': cartItems.map((item) => item.toJson()).toList(),
      'total': total,
      'cartTotal': cartTotal,
      'cartCount': cartCount,
      'message': message,
    };
  }
}