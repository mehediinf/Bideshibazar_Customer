// lib/presentation/widgets/product_card_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer' as developer;

import '../../core/network/api_constants.dart';
import '../../core/utils/cart_manager.dart';
import '../../core/utils/cart_helper.dart';
import '../../core/utils/wishlist_manager.dart';

class ProductCardWidget extends StatelessWidget {
  final dynamic product;
  final String sellerName;
  final VoidCallback onWishlistToggle;
  final Function(int newQuantity) onQuantityChanged;
  final VoidCallback? onTap;
  final bool useHorizontalLayout;
  final bool forceWishlistSelected;
  final Color? wishlistIconBackgroundColor;
  final Color? wishlistSelectedColor;
  final Color? wishlistUnselectedColor;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.sellerName,
    required this.onWishlistToggle,
    required this.onQuantityChanged,
    this.onTap,
    this.useHorizontalLayout = true,
    this.forceWishlistSelected = false,
    this.wishlistIconBackgroundColor,
    this.wishlistSelectedColor,
    this.wishlistUnselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final productData = _extractProductData();
    final cartManager = context.read<CartManager>();

    final int productId = productData.containsKey('productId')
        ? _parseProductId(productData['productId'])
        : _parseProductId(productData['id']);

    final int shopProductId = _parseProductId(productData['id']);

    final int cartQuantity = context.select<CartManager, int>(
      (manager) => manager.getProductQuantity(shopProductId),
    );
    final bool isInWishlist = context.select<WishlistManager, bool>(
      (manager) => manager.isInWishlist(productId),
    );
    final bool effectiveIsInWishlist = forceWishlistSelected || isInWishlist;

    if (useHorizontalLayout) {
      return _buildHorizontalCard(
        context,
        productData,
        shopProductId,
        cartQuantity,
        effectiveIsInWishlist,
        cartManager,
      );
    } else {
      return _buildGridCard(
        context,
        productData,
        shopProductId,
        cartQuantity,
        effectiveIsInWishlist,
        cartManager,
      );
    }
  }

  int _parseProductId(dynamic id) {
    if (id is int) return id;
    if (id is String) {
      try {
        return int.parse(id);
      } catch (e) {
        developer.log('Failed to parse product ID: $id');
        return 0;
      }
    }
    return 0;
  }

  Map<String, dynamic> _extractProductData() {
    if (product is Map) {
      return product as Map<String, dynamic>;
    } else {
      final hasQuantity = product.runtimeType.toString().contains(
        '_ProductWrapper',
      );

      return {
        'id': _safeGet(() => product.id, '0'),
        'name': _safeGet(() => product.name ?? product.title, ''),
        'image': '',
        'imageUrl': _safeGet(() => product.imageUrl, ''),
        'price': _parsePrice(_safeGet(() => product.price, '0.0')),
        'originalPrice': _parsePrice(_safeGet(() => product.oldPrice, '0.0')),
        'weight': _safeGet(() => product.weight, ''),
        'unit': _safeGet(() => product.unit ?? product.unit, ''),
        'displayWeight': _safeGet(() => product.displayWeight, ''),
        'hasOffer': _safeGet(() => product.hasOffer, false),
        'isInWishlist': hasQuantity
            ? _safeGet(() => product.isInWishlist, false)
            : false,
        'sellerId': _safeGet(() => product.sellerId ?? 0, 0),
      };
    }
  }

  T _safeGet<T>(T Function() getter, T defaultValue) {
    try {
      final result = getter();
      return result ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  double _parsePrice(String priceStr) {
    try {
      return double.parse(priceStr);
    } catch (e) {
      return 0.0;
    }
  }

  String _resolveImageUrl(Map<String, dynamic> data) {
    final imageUrl = data['imageUrl']?.toString() ?? '';
    if (imageUrl.isNotEmpty) return imageUrl;
    return _getImageUrl(data['image']?.toString());
  }

  // HomeView - Horizontal Card (Compact & Responsive)
  Widget _buildHorizontalCard(
    BuildContext context,
    Map<String, dynamic> data,
    int productId,
    int quantity,
    bool isInWishlist,
    CartManager cartManager,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.38;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
      },
      child: Container(
        width: cardWidth.clamp(140.0, 170.0),
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section - Larger
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CachedNetworkImage(
                        imageUrl: _resolveImageUrl(data),
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.contain,
                        fadeInDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade50,
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(
                                    0xFFFF6B35,
                                  ).withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade50,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 32,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      onWishlistToggle();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: wishlistIconBackgroundColor ?? Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: isInWishlist
                            ? (wishlistSelectedColor ?? Colors.pink)
                            : (wishlistUnselectedColor ?? Colors.grey.shade400),
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Section - Optimized
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name - Larger
                  SizedBox(
                    height: 36,
                    child: Text(
                      data['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Weight Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4F0),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${data['weight']} ${data['unit']}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Price & Add Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '€${data['price'].toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B35),
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (data['hasOffer'] == true &&
                                data['originalPrice'] != data['price'])
                              Text(
                                '€${data['originalPrice'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildQuantityButton(
                        context,
                        data,
                        productId,
                        quantity,
                        cartManager,
                        true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ProductListView - Grid Card (Improved & Responsive)
  Widget _buildGridCard(
    BuildContext context,
    Map<String, dynamic> data,
    int productId,
    int quantity,
    bool isInWishlist,
    CartManager cartManager,
  ) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          final isCompact = cardWidth < 170;
          final imageHeight = isCompact ? 112.0 : 125.0;
          final contentPadding = isCompact ? 8.5 : 10.0;
          final titleHeight = isCompact ? 38.0 : 34.0;
          final titleFontSize = isCompact ? 12.5 : 13.0;
          final titleSpacing = isCompact ? 5.0 : 6.0;
          final priceFontSize = isCompact ? 14.5 : 15.5;
          final oldPriceFontSize = isCompact ? 10.0 : 10.5;
          final weightFontSize = isCompact ? 10.0 : 10.5;
          final heartIconSize = isCompact ? 14.0 : 15.0;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: imageHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isCompact ? 10.0 : 12.0),
                          child: CachedNetworkImage(
                            imageUrl: _resolveImageUrl(data),
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            fadeInDuration: Duration.zero,
                            placeholderFadeInDuration: Duration.zero,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[50],
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(
                                      0xFFFF6B35,
                                    ).withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[50],
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey[300],
                                size: isCompact ? 32 : 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () {
                          onWishlistToggle();
                        },
                        child: Container(
                          padding: EdgeInsets.all(isCompact ? 5 : 6),
                          decoration: BoxDecoration(
                            color: wishlistIconBackgroundColor ?? Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isInWishlist
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: heartIconSize,
                            color: isInWishlist
                                ? (wishlistSelectedColor ?? Colors.pink)
                                : (wishlistUnselectedColor ??
                                      Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: titleHeight,
                          child: Text(
                            data['name'] ?? '',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.3,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        SizedBox(height: titleSpacing),

                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 6 : 7,
                            vertical: isCompact ? 2.5 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4F0),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: const Color(
                                0xFFFF6B35,
                              ).withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            data['displayWeight'] ??
                                '${data['weight']} ${data['unit']}',
                            style: TextStyle(
                              fontSize: weightFontSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF6B35),
                            ),
                          ),
                        ),

                        const Spacer(),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '€${data['price'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: priceFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF6B35),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (data['hasOffer'] == true &&
                                      data['originalPrice'] != data['price'])
                                    Text(
                                      '€${data['originalPrice'].toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: oldPriceFontSize,
                                        color: Colors.grey.shade500,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            _buildQuantityButton(
                              context,
                              data,
                              productId,
                              quantity,
                              cartManager,
                              isCompact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Quantity Button with Cart Integration
  Widget _buildQuantityButton(
    BuildContext context,
    Map<String, dynamic> data,
    int productId,
    int quantity,
    CartManager cartManager,
    bool isSmall,
  ) {
    if (quantity == 0) {
      return GestureDetector(
        onTap: () async {
          developer.log('Add to cart tapped');

          final canProceed = await CartHelper.checkBeforeAddToCart(context);

          if (!canProceed) {
            developer.log('Add to cart cancelled - requirements not met');
            return;
          }

          if (context.mounted) {
            await _addToCart(context, data, productId, cartManager);
          }
        },
        child: Container(
          width: isSmall ? 28 : 32,
          height: isSmall ? 28 : 32,
          decoration: BoxDecoration(
            color: isSmall ? Colors.white : const Color(0xFFFF6B35),
            borderRadius: BorderRadius.circular(isSmall ? 7 : 8),
            border: isSmall
                ? Border.all(color: const Color(0xFFFF6B35), width: 1.8)
                : null,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFFF6B35,
                ).withValues(alpha: isSmall ? 0.15 : 0.3),
                blurRadius: isSmall ? 4 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.add_rounded,
            color: isSmall ? const Color(0xFFFF6B35) : Colors.white,
            size: isSmall ? 16 : 18,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              developer.log('➖ Decrement cart quantity');

              if (quantity > 1) {
                await cartManager.updateQuantity(productId, quantity - 1);
                onQuantityChanged(quantity - 1);
              } else {
                await cartManager.removeItem(productId);
                onQuantityChanged(0);
              }
            },
            child: Container(
              width: isSmall ? 24 : 26,
              height: isSmall ? 26 : 30,
              alignment: Alignment.center,
              child: Icon(
                Icons.remove,
                color: Colors.white,
                size: isSmall ? 14 : 15,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 5 : 7),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 12 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              developer.log('➕ Increment cart quantity');

              await cartManager.updateQuantity(productId, quantity + 1);
              onQuantityChanged(quantity + 1);
            },
            child: Container(
              width: isSmall ? 24 : 26,
              height: isSmall ? 26 : 30,
              alignment: Alignment.center,
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: isSmall ? 14 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(
    BuildContext context,
    Map<String, dynamic> data,
    int productId,
    CartManager cartManager,
  ) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text('Adding to cart...'),
              ],
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFFFF6B35),
          ),
        );
      }

      final cartItem = CartItem(
        id: productId,
        name: data['name'] ?? '',
        image: data['imageUrl'] ?? _getImageUrl(data['image']),
        price: data['price'].toDouble(),
        originalPrice: data['originalPrice'].toDouble(),
        weight: data['weight']?.toString() ?? '',
        unit: data['unit'] ?? '',
        sellerId: data['sellerId'] ?? 0,
        sellerName: sellerName,
        quantity: 1,
      );

      final success = await cartManager.addItem(cartItem);

      if (success) {
        onQuantityChanged(1);

        if (context.mounted) {
          CartHelper.showSuccessMessage(
            context,
            '${data['name']} added to cart',
          );
        }
      } else {
        if (context.mounted) {
          CartHelper.showErrorMessage(
            context,
            'Failed to add to cart. Please try again.',
          );
        }
      }
    } catch (e) {
      developer.log('Error adding to cart: $e');
      if (context.mounted) {
        CartHelper.showErrorMessage(context, 'Error: ${e.toString()}');
      }
    }
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    if (imagePath.startsWith('http')) {
      return imagePath.replaceAll('\\', '/');
    }

    final cleanPath = imagePath.replaceAll('\\', '/');
    return '${ApiConstants.imageBaseUrl}uploads/product/$cleanPath';
  }
}
