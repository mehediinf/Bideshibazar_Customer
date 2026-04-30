// lib/presentation/widgets/free_delivery_banner.dart

import 'package:flutter/material.dart';

class _FreeDeliveryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Free Delivery on Your First Order!",
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
