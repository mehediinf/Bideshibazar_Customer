// lib/presentation/shop_checkout/shopping_bag_view.dart

import 'package:flutter/material.dart';

import '../../data/models/cart_product_item.dart';

class ShoppingBagView extends StatelessWidget {
  const ShoppingBagView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Shopping Bag",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [

          const SizedBox(height: 8),
          const _StepIndicator(),

          const SizedBox(height: 16),

          _FreeDeliveryBanner(),

          _CheckoutButton(total: 12.10),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _stepCircle('1', true),
          const Expanded(child: Divider(thickness: 1)),
          _stepCircle('2', false),
          const Expanded(child: Divider(thickness: 1)),
          _stepCircle('3', false),
        ],
      ),
    );
  }

  Widget _stepCircle(String label, bool active) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: active ? Colors.black : const Color(0xFFE0E0E0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: active ? Colors.white : Colors.black54,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FreeDeliveryBanner extends StatelessWidget {
  const _FreeDeliveryBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Add more items to unlock free delivery',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF795548),
        ),
      ),
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  final double total;

  const _CheckoutButton({required this.total});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Checkout  €${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
