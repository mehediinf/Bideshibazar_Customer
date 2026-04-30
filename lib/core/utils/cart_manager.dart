// lib/core/utils/cart_manager.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/cart_api_service.dart';
import 'shared_prefs_helper.dart';

class CartItem {
  final int id;
  final String name;
  final String image;
  final double price; // Discounted price or main price
  final double originalPrice; // Original price (for backward compatibility)
  final double? salesPriceWithCharge; // Sales price with charge from API
  final double? discount;
  final String weight;
  final String unit;
  final int sellerId;
  final String sellerName;
  int quantity;
  int? cartItemId; // API cart item ID

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.originalPrice,
    this.salesPriceWithCharge,
    this.discount,
    required this.weight,
    required this.unit,
    required this.sellerId,
    required this.sellerName,
    this.quantity = 1,
    this.cartItemId,
  });

  // Helper methods for price display logic
  bool get hasDiscount => discount != null && discount! > 0;

  // Display price: if discount exists, show discounted price, else show sales_price_with_charge or originalPrice
  double get displayPrice {
    if (hasDiscount) {
      return price; // Show discounted price
    } else {
      return salesPriceWithCharge ?? originalPrice; // Show original price
    }
  }

  // Original price for strikethrough (only if discount exists)
  double? get originalPriceForDisplay {
    if (hasDiscount) {
      return salesPriceWithCharge ?? originalPrice;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'originalPrice': originalPrice,
      'salesPriceWithCharge': salesPriceWithCharge,
      'discount': discount,
      'weight': weight,
      'unit': unit,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'quantity': quantity,
      'cartItemId': cartItemId,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0.0).toDouble(),
      salesPriceWithCharge: json['salesPriceWithCharge'] != null
          ? (json['salesPriceWithCharge'] as num).toDouble()
          : null,
      discount: json['discount'] != null
          ? (json['discount'] as num).toDouble()
          : null,
      weight: json['weight']?.toString() ?? '',
      unit: json['unit'] ?? '',
      sellerId: json['sellerId'] ?? 0,
      sellerName: json['sellerName'] ?? '',
      quantity: json['quantity'] ?? 1,
      cartItemId: json['cartItemId'],
    );
  }

  double get totalPrice => displayPrice * quantity;
}

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  List<CartItem> _items = [];
  static const String _cartKey = 'shopping_cart';
  bool _isSyncing = false;

  List<CartItem> get items => _items;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isSyncing => _isSyncing;

  /// Load cart from SharedPreferences
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartJson = prefs.getString(_cartKey);

      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(cartJson);
        _items = decoded.map((item) => CartItem.fromJson(item)).toList();
        debugPrint('✅ Loaded ${_items.length} items from local cart');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading cart: $e');
      _items = [];
    }
  }

  /// Save cart to SharedPreferences
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartJson);
      debugPrint('✅ Cart saved locally: ${_items.length} items');
    } catch (e) {
      debugPrint('❌ Error saving cart: $e');
    }
  }

  /// Sync local cart with server (Public method with loading state)
  Future<void> syncWithServer() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _syncCartFromServer();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Add item to cart (Local + API) - Requires Login
  Future<bool> addItem(CartItem item) async {
    try {
      // 🔐 Check if user is logged in
      final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint('❌ User not logged in - cannot add to cart');
        return false; // Return false to indicate login required
      }

      // 1. Add to local cart first (instant UI update)
      final existingIndex = _items.indexWhere((i) => i.id == item.id);

      if (existingIndex >= 0) {
        _items[existingIndex].quantity += item.quantity;
      } else {
        _items.add(item);
      }

      await _saveCart();
      notifyListeners();
      debugPrint('✅ Item added to local cart: ${item.name}');

      // 2. Sync with API in background
      try {
        final response = await CartApiService.addToCart(productId: item.id);
        debugPrint('✅ Item added to server cart: ${response['message']}');

        // 3. Fetch full cart to get cartItemId
        await _syncCartFromServer();
        debugPrint('✅ Cart synced after adding item');

      } catch (apiError) {
        debugPrint('⚠️ API sync failed, cart saved locally: $apiError');
        // Cart is already saved locally, so UI is fine
      }

      return true; // Success
    } catch (e) {
      debugPrint('❌ Error adding to cart: $e');
      return false;
    }
  }

  /// Internal method to sync cart from server (without setting isSyncing flag)
  Future<void> _syncCartFromServer() async {
    try {
      debugPrint('🔄 Syncing cart from server...');

      final response = await CartApiService.viewCart();

      if (response['cartItems'] != null) {
        final serverItems = response['cartItems'] as List;

        // Update local cart with server data
        _items.clear();

        for (var item in serverItems) {
          try {
            final shopProduct = item['shop_product'];
            final product = shopProduct?['product'];

            if (product != null) {
              // Extract prices with proper type handling
              final itemPrice = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
              final salesPriceWithCharge = double.tryParse(
                  shopProduct?['sales_price_with_charge']?.toString() ?? '0'
              ) ?? 0.0;
              final discount = item['discount'] != null
                  ? double.tryParse(item['discount']?.toString() ?? '0')
                  : null;

              // Parse IDs properly (handle both String and int)
              final productId = int.tryParse(item['product_id']?.toString() ?? '0') ?? 0;
              final cartItemId = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
              final sellerId = int.tryParse(item['seller_id']?.toString() ?? '0') ?? 0;
              final quantity = (double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0).toInt();

              _items.add(CartItem(
                id: productId,
                cartItemId: cartItemId,
                name: product['name']?.toString() ?? '',
                image: product['image']?.toString() ?? '',
                price: itemPrice, // Discounted price from API
                originalPrice: salesPriceWithCharge, // Original price for backward compatibility
                salesPriceWithCharge: salesPriceWithCharge, // Sales price with charge
                discount: discount,
                weight: item['weight']?.toString() ?? '',
                unit: product['unit']?['name']?.toString() ?? '',
                sellerId: sellerId,
                sellerName: 'Shop',
                quantity: quantity,
              ));

              debugPrint('✅ Added to cart: Product ID=$productId, Qty=$quantity, Price=$itemPrice');
            }
          } catch (itemError) {
            debugPrint('⚠️ Error processing cart item: $itemError');
            continue; // Skip this item and continue with next
          }
        }

        await _saveCart();
        notifyListeners();
        debugPrint('✅ Cart synced: ${_items.length} items');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error syncing cart from server: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Update item quantity (Local + API)
  Future<void> updateQuantity(int productId, int quantity) async {
    try {
      final index = _items.indexWhere((item) => item.id == productId);

      if (index >= 0) {
        final cartItemId = _items[index].cartItemId;

        // 1. Update local cart first
        if (quantity <= 0) {
          _items.removeAt(index);
        } else {
          _items[index].quantity = quantity;
        }

        await _saveCart();
        notifyListeners();
        debugPrint('✅ Quantity updated locally');

        // 2. Sync with API
        if (cartItemId != null) {
          try {
            if (quantity <= 0) {
              await CartApiService.removeFromCart(cartItemId: cartItemId);
              debugPrint('✅ Item removed from server');
            } else {
              await CartApiService.updateCart(
                cartItemId: cartItemId,
                quantity: quantity,
              );
              debugPrint('✅ Quantity updated on server');
            }
          } catch (apiError) {
            debugPrint('⚠️ API sync failed: $apiError');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating quantity: $e');
    }
  }

  /// Remove item from cart (Local + API)
  Future<void> removeItem(int productId) async {
    try {
      final index = _items.indexWhere((item) => item.id == productId);

      if (index >= 0) {
        final cartItemId = _items[index].cartItemId;

        // 1. Remove from local cart
        _items.removeAt(index);
        await _saveCart();
        notifyListeners();
        debugPrint('✅ Item removed from local cart');

        // 2. Remove from server
        if (cartItemId != null) {
          try {
            await CartApiService.removeFromCart(cartItemId: cartItemId);
            debugPrint('✅ Item removed from server');
          } catch (apiError) {
            debugPrint('⚠️ API sync failed: $apiError');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error removing item: $e');
    }
  }

  /// Clear entire cart (Local + API)
  Future<void> clearCart() async {
    try {
      // Store cart item IDs for API deletion
      final itemIds = _items
          .where((item) => item.cartItemId != null)
          .map((item) => item.cartItemId!)
          .toList();

      // 1. Clear local cart
      _items.clear();
      await _saveCart();
      notifyListeners();
      debugPrint('✅ Local cart cleared');

      // 2. Clear server cart
      for (var itemId in itemIds) {
        try {
          await CartApiService.removeFromCart(cartItemId: itemId);
        } catch (e) {
          debugPrint('⚠️ Failed to remove item $itemId from server: $e');
        }
      }
      debugPrint('✅ Server cart cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cart: $e');
    }
  }

  /// Get quantity of a specific product
  int getProductQuantity(int productId) {
    final item = _items.firstWhere(
          (item) => item.id == productId,
      orElse: () => CartItem(
        id: 0,
        name: '',
        image: '',
        price: 0,
        originalPrice: 0,
        weight: '',
        unit: '',
        sellerId: 0,
        sellerName: '',
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  /// Check if product is in cart
  bool isInCart(int productId) {
    return _items.any((item) => item.id == productId);
  }

  /// Get cart item by product ID
  CartItem? getCartItemByProductId(int productId) {
    try {
      return _items.firstWhere((item) => item.id == productId);
    } catch (e) {
      return null;
    }
  }
}