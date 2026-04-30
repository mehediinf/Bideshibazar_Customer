// lib/presentation/cart/cart_viewmodel.dart

import 'package:flutter/material.dart';
import '../../core/utils/app_error_helper.dart';
import '../../data/models/cart_model.dart';
import '../../core/services/cart_api_service.dart';

class CartViewModel extends ChangeNotifier {
  List<CartItemModel> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _totalItems = 0;
  double _totalPrice = 0.0;

  List<CartItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalItems => _totalItems;
  double get totalPrice => _totalPrice;

  /// Load cart from API
  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await CartApiService.viewCart();

      final cartResponse = CartResponseModel.fromJson(response);
      _cartItems = cartResponse.cartItems;
      _totalItems = cartResponse.total;

      // Calculate total price
      _calculateTotals();

      debugPrint('✅ Cart loaded: ${_cartItems.length} items');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = AppErrorHelper.toUserMessage(e);
      _isLoading = false;
      debugPrint('❌ Error loading cart: $e');
      notifyListeners();
    }
  }

  /// Add product to cart
  Future<bool> addToCart(int productId) async {
    try {
      debugPrint('🛒 Adding product $productId to cart...');

      final response = await CartApiService.addToCart(productId: productId);

      debugPrint('✅ ${response['message']}');

      // Reload cart to get updated data
      await loadCart();

      return true;
    } catch (e) {
      _errorMessage = AppErrorHelper.toUserMessage(e);
      debugPrint('❌ Error adding to cart: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update cart item quantity
  Future<bool> updateQuantity(int cartItemId, int quantity) async {
    try {
      debugPrint('🔄 Updating cart item $cartItemId to quantity $quantity...');

      if (quantity <= 0) {
        return await removeFromCart(cartItemId);
      }

      final response = await CartApiService.updateCart(
        cartItemId: cartItemId,
        quantity: quantity,
      );

      debugPrint('✅ ${response['message']}');

      // Update local data
      final cartResponse = CartResponseModel.fromJson(response);
      _cartItems = cartResponse.cartItems;
      _totalItems = cartResponse.cartCount ?? _cartItems.length;
      _totalPrice = cartResponse.cartTotal ?? 0.0;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = AppErrorHelper.toUserMessage(e);
      debugPrint('❌ Error updating cart: $e');
      notifyListeners();
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart(int cartItemId) async {
    try {
      debugPrint('🗑️ Removing cart item $cartItemId...');

      final response = await CartApiService.removeFromCart(
        cartItemId: cartItemId,
      );

      debugPrint('✅ ${response['message']}');

      // Update local data
      final cartResponse = CartResponseModel.fromJson(response);
      _cartItems = cartResponse.cartItems;
      _totalItems = cartResponse.cartCount ?? _cartItems.length;
      _totalPrice = cartResponse.cartTotal ?? 0.0;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = AppErrorHelper.toUserMessage(e);
      debugPrint('❌ Error removing from cart: $e');
      notifyListeners();
      return false;
    }
  }

  /// Calculate totals
  void _calculateTotals() {
    _totalPrice = 0.0;
    _totalItems = 0;

    for (var item in _cartItems) {
      _totalPrice += item.totalPrice;
      _totalItems += item.quantityDouble.toInt();
    }
  }

  /// Get quantity of specific product in cart
  int getProductQuantity(int productId) {
    final item = _cartItems.firstWhere(
          (item) => item.productId == productId,
      orElse: () => CartItemModel(
        id: 0,
        productId: 0,
        sellerId: 0,
        quantity: '0',
        wholesalePrice: '0',
        price: '0',
        weight: '0',
      ),
    );
    return item.quantityDouble.toInt();
  }

  /// Check if product is in cart
  bool isInCart(int productId) {
    return _cartItems.any((item) => item.productId == productId);
  }

  /// Get cart item by product ID
  CartItemModel? getCartItemByProductId(int productId) {
    try {
      return _cartItems.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh cart
  Future<void> refreshCart() async {
    await loadCart();
  }
}

