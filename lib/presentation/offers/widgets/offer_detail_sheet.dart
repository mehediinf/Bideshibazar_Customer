//lib/presentation/offers/widgets/offer_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/offer_model.dart';
import '../../../core/utils/cart_manager.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import '../../../core/utils/cart_helper.dart';

class OfferDetailSheet extends StatefulWidget {
  final OfferModel offer;
  final ProductModel product;

  const OfferDetailSheet({
    super.key,
    required this.offer,
    required this.product,
  });

  @override
  State<OfferDetailSheet> createState() => _OfferDetailSheetState();
}

class _OfferDetailSheetState extends State<OfferDetailSheet> {
  int currentImageIndex = 0;
  bool isAddingToCart = false;

  Future<void> _addToCart() async {
    // Check login first
    final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        CartHelper.showLoginRequiredDialog(context);
      }
      return;
    }

    // Validate product ID before proceeding
    final productId = widget.product.shopProductId;
    if (productId == 0) {
      if (mounted) {
        CartHelper.showErrorMessage(
          context,
          'Product ID not found. Cannot add to cart.',
        );
      }
      return;
    }

    setState(() {
      isAddingToCart = true;
    });

    try {
      final cartManager = context.read<CartManager>();

      // Create cart item from product
      final cartItem = CartItem(
        id: productId,
        name: widget.product.name,
        image: widget.product.image,
        price: widget.product.discountedPrice,
        originalPrice: double.tryParse(widget.product.originalPrice) ?? 0.0,
        weight: widget.product.weight ?? '1',
        unit: widget.product.unitName,
        sellerId: widget.product.sellerId ?? widget.offer.sellerId ?? 0,
        sellerName: widget.offer.sellerName,
        quantity: 1,
      );

      final success = await cartManager.addItem(cartItem);

      if (success && mounted) {
        CartHelper.showSuccessMessage(
          context,
          '${widget.product.name} added to cart',
        );
        // Close the bottom sheet after adding
        Navigator.pop(context);
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

    final List<String> images = [widget.offer.image];
    final totalImages = images.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false, 
            bottom: true,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${currentImageIndex + 1}/$totalImages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                ),

                // Image Section with PageView
                SizedBox(
                  height: 320,
                  child: PageView.builder(
                    itemCount: totalImages,
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Stack(
                          children: [

                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                images[index],
                                width: double.infinity,
                                height: 320,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 320,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 80,
                                    ),
                                  );
                                },
                              ),
                            ),

                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'OFFER PRICE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '€${widget.product.discountedPrice.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // First Order Delivery Badge
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'FIRST ORDER',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'DELIVERY CHARGE FREE',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
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
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Price Section
                        Row(
                          children: [
                            Text(
                              '€ ${widget.product.discountedPrice.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '€ ${widget.product.originalPrice}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '| ${widget.product.unitName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Fixed Add to Cart Button - Always visible at bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isAddingToCart ? null : _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C00),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isAddingToCart
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'ADD TO CART',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}




