// lib/presentation/cart/cart_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/cart_manager.dart';
import '../../core/network/api_constants.dart';
import '../../core/utils/shared_prefs_helper.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {

  @override
  void initState() {
    super.initState();

    // Check login and sync with server when cart view opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isLoggedIn = await SharedPrefsHelper.isLoggedIn();

      if (!isLoggedIn) {
        // User not logged in - show message and go back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to view your cart'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to login
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        }
        return;
      }

      // User is logged in - sync cart
      if (mounted) {
        context.read<CartManager>().syncWithServer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          Consumer<CartManager>(
            builder: (context, cartManager, _) {
              if (cartManager.items.isEmpty) return const SizedBox.shrink();

              return IconButton(
                icon: cartManager.isSyncing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.refresh),
                onPressed: cartManager.isSyncing
                    ? null
                    : () => cartManager.syncWithServer(),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartManager>(
        builder: (context, cartManager, child) {
          if (cartManager.isSyncing && cartManager.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFFF6B35),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading cart...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          if (cartManager.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Syncing indicator
              if (cartManager.isSyncing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.orange[50],
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.orange[700],
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Syncing with server...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => cartManager.syncWithServer(),
                  color: const Color(0xFFFF6B35),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = cartManager.items[index];
                      return _buildCartItem(context, item, cartManager);
                    },
                  ),
                ),
              ),
              _buildBottomBar(context, cartManager),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(
      BuildContext context,
      CartItem item,
      CartManager cartManager,
      ) {
    // Handle image URL properly
    String productImage;
    if (item.image.startsWith('http://') || item.image.startsWith('https://')) {
      // Already a full URL
      productImage = item.image;
    } else if (item.image.startsWith('uploads/')) {
      // Path starts with uploads/
      productImage = '${ApiConstants.imageBaseUrl}${item.image}';
    } else {
      // Just filename or relative path
      productImage = '${ApiConstants.imageBaseUrl}uploads/product/${item.image}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              productImage,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.weight} ${item.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.sellerName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Price Display Logic
                        if (item.hasDiscount) ...[
                          // Discount আছে - Discounted price বড় করে দেখাবে
                          Text(
                            '€${item.displayPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Original price কাটা দাগ দিয়ে
                          if (item.originalPriceForDisplay != null)
                            Text(
                              '€${item.originalPriceForDisplay!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ] else ...[
                          // Discount নাই - শুধু sales_price_with_charge দেখাবে
                          Text(
                            '€${item.displayPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    // Quantity Control
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFF6B35),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              if (item.quantity > 1) {
                                await cartManager.updateQuantity(
                                  item.id,
                                  item.quantity - 1,
                                );
                              } else {
                                _showRemoveDialog(context, item, cartManager);
                              }
                            },
                            child: Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.remove,
                                size: 18,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.1),
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await cartManager.updateQuantity(
                                item.id,
                                item.quantity + 1,
                              );
                            },
                            child: Container(
                              width: 32,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Delete Button
          IconButton(
            onPressed: () => _showRemoveDialog(context, item, cartManager),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(
      BuildContext context,
      CartItem item,
      CartManager cartManager,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.name}" from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await cartManager.removeItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item removed from cart'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartManager cartManager) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Items:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${cartManager.totalItems}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Price:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '€${cartManager.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cartManager.isSyncing
                    ? null
                    : () {
                  // Navigate to checkout page
                  Navigator.pushNamed(context, '/checkout');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: cartManager.isSyncing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
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
}