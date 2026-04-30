// lib/presentation/widgets/floating_cart_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/cart_manager.dart';

class FloatingCartWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const FloatingCartWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartManager>(
      builder: (context, cartManager, child) {
        if (cartManager.totalItems == 0) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Cart Icon with Badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.shopping_cart_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B35),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  '${cartManager.totalItems > 99 ? '99+' : cartManager.totalItems}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Item Count & Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${cartManager.totalItems} item${cartManager.totalItems > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (cartManager.isSyncing) ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Delivery Charges may apply',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price & Arrow
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '€${cartManager.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}