// lib/presentation/widgets/search_product_card_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_constants.dart';
import '../../core/utils/cart_manager.dart';
import '../../core/utils/wishlist_manager.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/cart_helper.dart';
import 'dart:developer' as developer;

class SearchProductCardWidget extends StatefulWidget {
  final dynamic product;
  final VoidCallback? onTap;

  const SearchProductCardWidget({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  State<SearchProductCardWidget> createState() =>
      _SearchProductCardWidgetState();
}

class _SearchProductCardWidgetState extends State<SearchProductCardWidget> {
  final WishlistManager _wishlistManager = WishlistManager();

  @override
  void initState() {
    super.initState();
    developer.log('SearchProductCard initialized for: ${widget.product['name']}');
  }

  // Get product ID safely
  int? _getProductId() {
    final id = widget.product['id'] ??
        widget.product['shop_product_id'] ??
        widget.product['product_id'];

    if (id == null) return null;
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  // Check if product is in wishlist
  bool _isInWishlist() {
    final productId = _getProductId();
    if (productId == null) return false;
    return _wishlistManager.isInWishlist(productId);
  }

  // Toggle wishlist
  Future<void> _toggleWishlist() async {
    developer.log('⭐ Wishlist button tapped');

    final productId = _getProductId();
    if (productId == null) {
      return;
    }

    await _wishlistManager.toggleWishlist(context, productId);

    // Update UI
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addToCart(CartManager cartManager) async {
    developer.log('➕ Add to cart tapped');

    // Check login first
    final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        CartHelper.showLoginRequiredDialog(context);
      }
      return;
    }

    try {
      final shopProductId = _getProductId();

      if (shopProductId == null) {
        if (mounted) {
          CartHelper.showErrorMessage(context, 'Product ID not found');
        }
        return;
      }

      final name = widget.product['name'] ?? '';
      final image = widget.product['image'] ?? '';
      final priceWithCharge = double.tryParse(
          widget.product['sales_price_with_charge']?.toString() ?? '0'
      ) ?? 0.0;
      final salePrice = double.tryParse(
          widget.product['sale_price']?.toString() ?? '0'
      ) ?? 0.0;
      final weight = widget.product['weight']?.toString() ?? '';
      final unit = widget.product['unit_name'] ?? '';
      final sellerId = widget.product['seller_id'] as int? ?? 0;
      final shopName = widget.product['shop_name'] ?? 'Shop';

      developer.log('🛒 Adding to cart: $name (ID: $shopProductId)');

      final cartItem = CartItem(
        id: shopProductId,
        name: name,
        image: image,
        price: priceWithCharge,
        originalPrice: salePrice,
        weight: weight,
        unit: unit,
        sellerId: sellerId,
        sellerName: shopName,
        quantity: 1,
      );

      final success = await cartManager.addItem(cartItem);

      if (success && mounted) {
        CartHelper.showSuccessMessage(
          context,
          '$name added to cart',
        );
      } else if (!success && mounted) {
        CartHelper.showErrorMessage(
          context,
          'Failed to add to cart',
        );
      }
    } catch (e) {
      if (mounted) {
        CartHelper.showErrorMessage(
          context,
          'Something went wrong',
        );
      }
    }
  }

  Future<void> _updateQuantity(CartManager cartManager, int newQuantity) async {
    developer.log('🔄 Updating quantity to: $newQuantity');

    final shopProductId = _getProductId();

    if (shopProductId == null) return;

    // Check login
    final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        CartHelper.showLoginRequiredDialog(context);
      }
      return;
    }

    if (newQuantity <= 0) {
      await cartManager.removeItem(shopProductId);
    } else {
      await cartManager.updateQuantity(shopProductId, newQuantity);
    }
  }

  String _getImageUrl(String? image) {
    if (image == null || image.isEmpty) return '';
    if (image.startsWith('http')) return image;

    // Use ApiConstants helper method
    return ApiConstants.getImageUrl('product/$image');
  }

  @override
  Widget build(BuildContext context) {
    final String productName = widget.product['name'] ?? '';
    final String price = widget.product['sales_price_with_charge'] ?? '0.00';
    final String weight = widget.product['weight'] ?? '';
    final String unitName = widget.product['unit_name'] ?? '';
    final String imageUrl = _getImageUrl(widget.product['image']);

    // Get product ID and wishlist status
    final shopProductId = _getProductId();
    final bool isInWishlist = _isInWishlist();

    return Consumer<CartManager>(
      builder: (context, cartManager, child) {
        // Get quantity from cart
        final int quantity = shopProductId != null
            ? cartManager.getProductQuantity(shopProductId)
            : 0;

        return InkWell(
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              developer.log('onTap callback is NULL!');
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image with Shadow
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[50],
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey[300],
                              size: 40,
                            ),
                          );
                        },
                      )
                          : Container(
                        color: Colors.grey[50],
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey[300],
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                            color: Color(0xFF212121),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '€ $price',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                                letterSpacing: -0.3,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 1.5,
                              height: 14,
                              color: Colors.grey[300],
                            ),
                            Expanded(
                              child: Text(
                                '$weight $unitName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions Column
                  Column(
                    children: [
                      // Favorite Button with WishlistManager
                      InkWell(
                        onTap: () {
                          _toggleWishlist();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey(isInWishlist),
                              color: isInWishlist
                                  ? const Color(0xFFE91E63)
                                  : Colors.grey[400],
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Enhanced Add to Cart or Quantity Controls
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: quantity == 0
                            ? _buildAddButton(cartManager)
                            : _buildQuantityControls(cartManager, quantity),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton(CartManager cartManager) {
    return InkWell(
      onTap: () => _addToCart(cartManager),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        key: const ValueKey('add_button'),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFDD835),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFDD835).withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.add_rounded,
          size: 24,
          color: Color(0xFF212121),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(CartManager cartManager, int quantity) {
    return Container(
      key: const ValueKey('quantity_controls'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42A5F5).withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement Button
          InkWell(
            onTap: () {
              _updateQuantity(cartManager, quantity - 1);
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Container(
              width: 34,
              height: 42,
              alignment: Alignment.center,
              child: const Icon(
                Icons.remove_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          // Quantity Display
          Container(
            constraints: const BoxConstraints(minWidth: 38),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Increment Button
          InkWell(
            onTap: () {
              _updateQuantity(cartManager, quantity + 1);
            },
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Container(
              width: 34,
              height: 42,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}