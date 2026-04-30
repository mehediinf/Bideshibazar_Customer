// lib/presentation/products/product_detail_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/product_detail_service.dart';
import '../../core/network/api_constants.dart';
import '../../core/utils/cart_manager.dart';
import '../../core/utils/wishlist_manager.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/cart_helper.dart';
import '../../core/utils/app_error_helper.dart';
import '../widgets/image_viewer.dart';
import 'dart:developer' as developer;

class ProductDetailView extends StatefulWidget {
  final int shopProductId;
  final String? productName;

  const ProductDetailView({
    super.key,
    required this.shopProductId,
    this.productName,
  });

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  final WishlistManager _wishlistManager = WishlistManager();

  Map<String, dynamic>? productData;
  List<Map<String, dynamic>> relatedProducts = [];
  bool isLoading = true;
  bool isRelatedLoading = false;
  String? errorMessage;
  String? relatedErrorMessage;
  int quantity = 0;
  bool isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
    _fetchRelatedProducts();
    _loadCartQuantity();
  }

  Future<void> _loadCartQuantity() async {
    final cartManager = context.read<CartManager>();
    // Get shop_product_id from productData
    if (productData != null) {
      final shopProductId = productData!['shop_product_id'] as int?;
      if (shopProductId != null) {
        setState(() {
          quantity = cartManager.getProductQuantity(shopProductId);
        });
      }
    }
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ProductDetailService.fetchProductDetails(
        widget.shopProductId,
      );

      if (response['product'] != null) {
        setState(() {
          productData = response['product'];
          isLoading = false;
        });

        // Load cart quantity after product data is available
        _loadCartQuantity();
      } else {
        setState(() {
          errorMessage = 'Product not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = AppErrorHelper.toUserMessage(e);
        isLoading = false;
      });
    }
  }

  Future<void> _fetchRelatedProducts() async {
    setState(() {
      isRelatedLoading = true;
      relatedErrorMessage = null;
    });

    try {
      final response = await ProductDetailService.fetchRelatedProducts(
        widget.shopProductId,
      );

      if (!mounted) return;

      setState(() {
        relatedProducts = response
            .where((item) => _parseInt(item['id']) != widget.shopProductId)
            .toList();
        isRelatedLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        relatedErrorMessage = AppErrorHelper.toUserMessage(e);
        isRelatedLoading = false;
      });
    }
  }

  // Check if product is in wishlist
  int _wishlistProductId() {
    if (productData != null) {
      final productId = _parseInt(productData!['product_id']);
      if (productId > 0) return productId;

      final shopProductId = _parseInt(productData!['shop_product_id']);
      if (shopProductId > 0) return shopProductId;
    }
    return widget.shopProductId;
  }

  bool _isInWishlist() {
    return _wishlistManager.isInWishlist(_wishlistProductId());
  }

  // Toggle wishlist with WishlistManager
  Future<void> _toggleWishlist() async {
    developer.log('⭐ Wishlist button tapped in ProductDetail');

    final productId = _wishlistProductId();
    await _wishlistManager.toggleWishlist(context, productId);

    // Update UI
    if (mounted) {
      setState(() {});
    }
  }

  String _getImageUrl(String? image) {
    if (image == null || image.isEmpty) return '';
    if (image.startsWith('http')) return image;

    final normalizedImage = image.replaceAll('\\', '/');
    return '${ApiConstants.imageBaseUrl}uploads/product/$normalizedImage';
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) {
      return value.toInt();
    }
    return 0;
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  bool _hasDiscount(
    dynamic salePrice,
    dynamic priceWithCharge,
    dynamic discount,
  ) {
    if (_parseDouble(discount) > 0) {
      return true;
    }

    final original = _parseDouble(salePrice);
    final current = _parseDouble(priceWithCharge);
    return original > current && current > 0;
  }

  String _formatWeight(dynamic weight, dynamic unit) {
    final weightText = weight?.toString().trim() ?? '';
    final unitText = unit?.toString().trim() ?? '';

    if (weightText.isEmpty && unitText.isEmpty) {
      return '';
    }

    if (weightText.isEmpty) {
      return unitText;
    }

    if (unitText.isEmpty) {
      return weightText;
    }

    return '$weightText $unitText';
  }

  Map<String, dynamic> _normalizeRelatedProduct(Map<String, dynamic> item) {
    final product = item['product'] is Map<String, dynamic>
        ? item['product'] as Map<String, dynamic>
        : <String, dynamic>{};
    final seller = item['seller'] is Map<String, dynamic>
        ? item['seller'] as Map<String, dynamic>
        : <String, dynamic>{};
    final category = product['category'] is Map<String, dynamic>
        ? product['category'] as Map<String, dynamic>
        : <String, dynamic>{};
    final unit = product['unit'] is Map<String, dynamic>
        ? product['unit'] as Map<String, dynamic>
        : <String, dynamic>{};

    return {
      'shop_product_id': _parseInt(item['id']),
      'product_id': _parseInt(product['id']),
      'name': product['name']?.toString() ?? '',
      'heading': product['heading']?.toString() ?? '',
      'image': product['image']?.toString() ?? '',
      'shop_name': seller['shop_name']?.toString() ?? 'Shop',
      'category_name': category['name']?.toString() ?? '',
      'sale_price': item['sale_price']?.toString() ?? '0',
      'sales_price_with_charge':
          item['sales_price_with_charge']?.toString() ?? '0',
      'discount_amount': item['discount_amount']?.toString(),
      'weight_label': _formatWeight(
        item['weight'] ?? product['weight'],
        unit['name'],
      ),
      'has_offer': _hasDiscount(
        item['sale_price'],
        item['sales_price_with_charge'],
        item['discount_amount'],
      ),
    };
  }

  void _openImageViewer(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          imageUrl: imageUrl,
          heroTag: 'product_image_${widget.shopProductId}',
        ),
      ),
    );
  }

  Future<void> _shareProduct() async {
    if (productData == null) return;

    final name =
        productData!['name']?.toString().trim().isNotEmpty == true
            ? productData!['name'].toString().trim()
            : 'Product';
    final shopName = productData!['shop_name']?.toString().trim() ?? '';
    final priceText = productData!['sales_price_with_charge']?.toString() ?? '';
    final imageUrl = _getImageUrl(productData!['image']?.toString());

    final lines = <String>[
      'Check this product on BideshiBazar:',
      name,
      if (priceText.isNotEmpty) 'Price: €$priceText',
      if (shopName.isNotEmpty) 'Shop: $shopName',
      if (imageUrl.isNotEmpty) imageUrl,
    ];

    try {
      await Share.share(lines.join('\n'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open share options.')),
      );
    }
  }

  Future<void> _addToCart() async {
    if (productData == null || quantity <= 0) return;

    // Check login first
    final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        CartHelper.showLoginRequiredDialog(context);
      }
      return;
    }

    setState(() {
      isAddingToCart = true;
    });

    try {
      final cartManager = context.read<CartManager>();

      // Use shop_product_id as the main product ID
      final shopProductId = productData!['shop_product_id'] as int;
      final name = productData!['name'] ?? '';
      final image = productData!['image'] ?? '';
      final salePrice =
          double.tryParse(productData!['sale_price']?.toString() ?? '0') ?? 0.0;
      final priceWithCharge =
          double.tryParse(
            productData!['sales_price_with_charge']?.toString() ?? '0',
          ) ??
          0.0;
      final weight = productData!['weight']?.toString() ?? '';
      final unit = productData!['unit_name'] ?? '';
      final sellerId = productData!['seller_id'] as int? ?? 0;
      final shopName = productData!['shop_name'] ?? 'Shop';

      // Check if item already exists in cart
      final existingQuantity = cartManager.getProductQuantity(shopProductId);

      if (existingQuantity > 0) {
        // Update quantity
        await cartManager.updateQuantity(shopProductId, quantity);

        if (mounted) {
          CartHelper.showSuccessMessage(
            context,
            'Cart updated: $quantity × $name',
          );
        }
      } else {
        // Add new item
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
          quantity: quantity,
        );

        final success = await cartManager.addItem(cartItem);

        if (success && mounted) {
          CartHelper.showSuccessMessage(
            context,
            'Added $quantity × $name to cart',
          );
        } else if (!success && mounted) {
          CartHelper.showErrorMessage(
            context,
            'Failed to add to cart. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CartHelper.showErrorMessage(
          context,
          'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get wishlist status from WishlistManager
    final bool isInWishlist = _isInWishlist();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.productName ?? 'Product Details',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Wishlist Button with WishlistManager
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isInWishlist ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isInWishlist),
                color: isInWishlist ? const Color(0xFFE91E63) : Colors.black,
                size: 26,
              ),
            ),
            onPressed: () {
              _toggleWishlist();
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: _shareProduct,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorWidget()
          : _buildProductContent(),
      bottomNavigationBar: !isLoading && errorMessage == null
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error Loading Product',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error',
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchProductDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductContent() {
    if (productData == null) return const SizedBox.shrink();

    final product = productData!;
    final String imageUrl = _getImageUrl(product['image']);
    final String name = product['name'] ?? '';
    final String salePrice = product['sale_price']?.toString() ?? '0';
    final String priceWithCharge =
        product['sales_price_with_charge']?.toString() ?? '0';
    final String unit = product['unit_name'] ?? '';
    final String weight = product['weight']?.toString() ?? '';
    final bool hasOffer = product['has_offer'] ?? false;
    final String? discountAmount = product['discount_amount']?.toString();
    final String shopName = product['shop_name'] ?? '';
    final String categoryName = product['category_name'] ?? '';
    final String shortDesc = product['short_description'] ?? '';
    final String longDesc = product['long_description'] ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Section with Click to View
          GestureDetector(
            onTap: imageUrl.isNotEmpty
                ? () => _openImageViewer(imageUrl)
                : null,
            child: Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey.shade100,
              child: Stack(
                children: [
                  // Image with Hero animation
                  Center(
                    child: imageUrl.isNotEmpty
                        ? Hero(
                            tag: 'product_image_${widget.shopProductId}',
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image_not_supported,
                                  size: 100,
                                  color: Colors.grey.shade400,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.image_not_supported,
                            size: 100,
                            color: Colors.grey.shade400,
                          ),
                  ),
                  // Zoom indicator icon
                  if (imageUrl.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.zoom_in, color: Colors.white, size: 20),
                            SizedBox(width: 4),
                            Text(
                              'Tap to view',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Product Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Product Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Shop Name
                Row(
                  children: [
                    Icon(Icons.store, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      shopName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price Section
                Row(
                  children: [
                    Text(
                      '€$priceWithCharge',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (hasOffer && discountAmount != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '€$salePrice',
                            style: TextStyle(
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-€$discountAmount OFF',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Weight/Unit
                Text(
                  '$weight $unit',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                Divider(color: Colors.grey.shade300),
                const SizedBox(height: 16),

                // Short Description
                if (shortDesc.isNotEmpty) ...[
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Html(
                    data: shortDesc,
                    style: {
                      "body": Style(
                        fontSize: FontSize(15),
                        color: Colors.grey.shade700,
                        lineHeight: const LineHeight(1.6),
                      ),
                      "p": Style(margin: Margins.only(bottom: 8)),
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Long Description
                if (longDesc.isNotEmpty) ...[
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Html(
                    data: longDesc,
                    style: {
                      "body": Style(
                        fontSize: FontSize(15),
                        color: Colors.grey.shade700,
                        lineHeight: const LineHeight(1.6),
                      ),
                      "p": Style(margin: Margins.only(bottom: 8)),
                    },
                  ),
                ],

                const SizedBox(height: 24),
                _buildRelatedProductsSection(),

                const SizedBox(height: 80), // Space for bottom bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity Selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF6B35), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: quantity > 0
                        ? () {
                            setState(() {
                              quantity--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove),
                    color: quantity > 0 ? const Color(0xFFFF6B35) : Colors.grey,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        quantity++;
                      });
                    },
                    icon: const Icon(Icons.add),
                    color: const Color(0xFFFF6B35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Add to Cart Button
            Expanded(
              child: ElevatedButton(
                onPressed: quantity > 0 && !isAddingToCart ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: isAddingToCart
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        quantity > 0 ? 'Add to Cart' : 'Select Quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedProductsSection() {
    if (isRelatedLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 18),
          const Text(
            'You May Also Like',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey.shade300),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFFFF3E8), const Color(0xFFFFFAF5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFE0CC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You May Also Like',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Picked from the same shop for a quick add-on.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (relatedErrorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  relatedErrorMessage!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                ),
              ],
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final cardWidth = screenWidth < 380 ? 188.0 : 210.0;
                  final cardHeight = screenWidth < 380 ? 300.0 : 286.0;

                  return SizedBox(
                    height: cardHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: relatedProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final related = _normalizeRelatedProduct(
                          relatedProducts[index],
                        );
                        return _buildRelatedProductCard(
                          related,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductCard(
    Map<String, dynamic> related, {
    required double cardWidth,
    required double cardHeight,
  }) {
    final imageUrl = _getImageUrl(related['image']?.toString());
    final hasOffer = related['has_offer'] == true;
    final priceWithCharge =
        related['sales_price_with_charge']?.toString() ?? '0';
    final salePrice = related['sale_price']?.toString() ?? '0';
    final weightLabel = related['weight_label']?.toString() ?? '';
    final categoryName = related['category_name']?.toString() ?? '';
    final shopName = related['shop_name']?.toString() ?? 'Shop';
    final name = related['heading']?.toString().isNotEmpty == true
        ? related['heading'].toString()
        : related['name']?.toString() ?? '';
    final shopProductId = related['shop_product_id'] as int? ?? 0;
    final imageHeight = cardHeight * 0.46;
    final isCompact = cardWidth < 200;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailView(
              shopProductId: shopProductId,
              productName: related['name']?.toString(),
            ),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFCF8), Color(0xFFFFF4EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE6D2), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: imageHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF9F4EF),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image_not_supported_outlined,
                                size: 44,
                                color: Colors.grey.shade400,
                              ),
                            )
                          : Icon(
                              Icons.image_not_supported_outlined,
                              size: 44,
                              color: Colors.grey.shade400,
                            ),
                    ),
                  ),
                  if (categoryName.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  isCompact ? 10 : 12,
                  14,
                  isCompact ? 12 : 14,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isVeryTight = constraints.maxHeight <= 74;
                    final showWeightChip =
                        weightLabel.isNotEmpty &&
                        constraints.maxHeight > (isCompact ? 122 : 132);
                    final nameMaxLines = isVeryTight
                        ? 1
                        : (showWeightChip ? 2 : 3);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: isVeryTight ? 4 : (isCompact ? 6 : 8)),
                        Flexible(
                          child: isVeryTight
                              ? Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                      height: 1.05,
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: nameMaxLines,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: isCompact ? 14 : 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        height: 1.18,
                                      ),
                                    ),
                                    if (showWeightChip) ...[
                                      SizedBox(height: isCompact ? 6 : 7),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: isCompact ? 4 : 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          weightLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                        SizedBox(height: isVeryTight ? 6 : (isCompact ? 8 : 10)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '€$priceWithCharge',
                                      style: TextStyle(
                                        fontSize: isCompact ? 18 : 20,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFF6B35),
                                      ),
                                    ),
                                  ),
                                  if (hasOffer)
                                    Text(
                                      '€$salePrice',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(isCompact ? 7 : 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: isCompact ? 16 : 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
