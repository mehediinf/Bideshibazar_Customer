// lib/presentation/products/products_near_you_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bideshibazar/core/network/api_constants.dart';
import 'package:bideshibazar/core/utils/cart_manager.dart';
import 'package:bideshibazar/core/utils/wishlist_manager.dart';
import 'package:bideshibazar/core/utils/shared_prefs_helper.dart';
import 'package:bideshibazar/core/utils/cart_helper.dart';
import 'product_detail_view.dart';
import 'dart:developer' as developer;

class ProductsNearYouView extends StatefulWidget {
  final List<Map<String, dynamic>> sellers;
  final String street;

  const ProductsNearYouView({
    super.key,
    required this.sellers,
    required this.street,
  });

  @override
  State<ProductsNearYouView> createState() => _ProductsNearYouViewState();
}

class _ProductsNearYouViewState extends State<ProductsNearYouView> {
  final WishlistManager _wishlistManager = WishlistManager();
  int selectedSellerIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSeller = widget.sellers[selectedSellerIndex];
    final products = selectedSeller['products'] as List<dynamic>;

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
        title: const Text(
          'Products near you',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Seller Tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.sellers.length,
              itemBuilder: (context, index) {
                final seller = widget.sellers[index];
                final isSelected = index == selectedSellerIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSellerIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFC107) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFFC107) : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        seller['shop_name'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.black : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Products Grid
          Expanded(
            child: Consumer<CartManager>(
              builder: (context, cartManager, child) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product, selectedSeller, cartManager);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      Map<String, dynamic> product,
      Map<String, dynamic> seller,
      CartManager cartManager,
      ) {
    final String rawImage = product['image'] ?? '';

    final String imageUrl = rawImage.startsWith('http')
        ? rawImage
        : '${ApiConstants.imageBaseUrl}uploads/product/$rawImage';

    final String name = product['name'] ?? '';
    final String priceWithCharge = product['sales_price_with_charge']?.toString() ?? '0';
    final String salePrice = product['sale_price']?.toString() ?? '0';
    final String unit = product['unit_name'] ?? '';
    final String weight = product['weight']?.toString() ?? '1';
    final int shopProductId = product['id'] ?? 0;
    final int sellerId = seller['seller_id'] ?? 0;
    final String shopName = seller['shop_name'] ?? 'Shop';

    // Get quantity from cart
    final int quantity = cartManager.getProductQuantity(shopProductId);

    // Get wishlist status
    final bool isInWishlist = _wishlistManager.isInWishlist(shopProductId);

    // Wrap entire card with GestureDetector to make it clickable
    return GestureDetector(
      onTap: () {
        developer.log('Product Name: $name');
        developer.log('Product ID: $shopProductId');

        // Navigate to Product Detail View
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(
              shopProductId: shopProductId,
              productName: name,
            ),
          ),
        ).then((_) {
          // Refresh UI after returning from detail view
          if (mounted) {
            setState(() {});
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wishlist Icon with WishlistManager
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () {
                    _toggleWishlist(shopProductId);
                  },
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
                          : Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            // Product Image
            Expanded(
              child: Center(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey.shade300,
                    );
                  },
                )
                    : Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
              ),
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    '€ $priceWithCharge',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Product Name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Unit
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Add Button or Quantity Control
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: quantity == 0
                    ? _buildAddButton(
                  product,
                  seller,
                  cartManager,
                )
                    : _buildQuantityControl(
                  shopProductId,
                  quantity,
                  cartManager,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle wishlist with WishlistManager
  Future<void> _toggleWishlist(int productId) async {

    await _wishlistManager.toggleWishlist(context, productId);

    // Update UI
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildAddButton(
      Map<String, dynamic> product,
      Map<String, dynamic> seller,
      CartManager cartManager,
      ) {
    return GestureDetector(
      onTap: () async {
        await _addToCart(product, seller, cartManager);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFFFC107),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC107).withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          size: 18,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildQuantityControl(
      int shopProductId,
      int quantity,
      CartManager cartManager,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC107).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement
          GestureDetector(
            onTap: () async {
              await _updateQuantity(shopProductId, quantity - 1, cartManager);
            },
            child: Container(
              width: 28,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(
                Icons.remove,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
          // Quantity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // Increment
          GestureDetector(
            onTap: () async {
              await _updateQuantity(shopProductId, quantity + 1, cartManager);
            },
            child: Container(
              width: 28,
              height: 32,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(
      Map<String, dynamic> product,
      Map<String, dynamic> seller,
      CartManager cartManager,
      ) async {
    // Check login
    final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        CartHelper.showLoginRequiredDialog(context);
      }
      return;
    }

    try {
      final shopProductId = product['id'] ?? 0;
      final name = product['name'] ?? '';
      final image = product['image'] ?? '';
      final priceWithCharge = double.tryParse(
        product['sales_price_with_charge']?.toString() ?? '0',
      ) ??
          0.0;
      final salePrice =
          double.tryParse(product['sale_price']?.toString() ?? '0') ?? 0.0;
      final weight = product['weight']?.toString() ?? '1';
      final unit = product['unit_name'] ?? '';
      final sellerId = seller['seller_id'] ?? 0;
      final shopName = seller['shop_name'] ?? 'Shop';

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

  Future<void> _updateQuantity(
      int shopProductId,
      int newQuantity,
      CartManager cartManager,
      ) async {
    // Check login
    final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        CartHelper.showLoginRequiredDialog(context);
      }
      return;
    }

    try {
      if (newQuantity <= 0) {
        await cartManager.removeItem(shopProductId);
      } else {
        await cartManager.updateQuantity(shopProductId, newQuantity);
      }
    } catch (e) {
      if (mounted) {
        CartHelper.showErrorMessage(
          context,
          'Failed to update quantity',
        );
      }
    }
  }
}