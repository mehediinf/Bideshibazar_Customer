// lib/data/models/cart_product_item.dart

import 'package:flutter/material.dart';

class CartProductItem extends StatelessWidget {
  final String image;
  final String title;
  final double price;
  final int quantity;
  final String unit;

  const CartProductItem({
    super.key,
    required this.image,
    required this.title,
    required this.price,
    required this.quantity,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Image.asset(
            image,
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "€ ${price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

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

          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {},
              ),
              _QuantityControl(quantity: quantity),
            ],
          )
        ],
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;

  const _QuantityControl({required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove, size: 16),
          const SizedBox(width: 8),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.add, size: 16),
        ],
      ),
    );
  }
}


