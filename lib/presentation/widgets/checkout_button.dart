// lib/presentation/widgets/checkout_button.dart

import 'package:flutter/material.dart';

class _CheckoutButton extends StatelessWidget {
  final double total;

  const _CheckoutButton({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          onPressed: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Checkout",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "€ ${total.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


