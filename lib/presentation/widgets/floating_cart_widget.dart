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
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2F8BFF), Color(0xFF1F6FE5), Color(0xFF155CC6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1459BE).withValues(alpha: 0.34),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8A3D),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 1.1,
                                ),
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
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
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price & Arrow
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.26),
                              Colors.white.withValues(alpha: 0.16),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                            width: 0.9,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '€${cartManager.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 19,
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