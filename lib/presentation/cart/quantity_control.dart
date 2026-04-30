// lib/presentation/cart/quantity_control.dart

import 'package:flutter/material.dart';

class _QuantityControl extends StatelessWidget {
  final int quantity;

  const _QuantityControl({required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _btn(Icons.remove),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(quantity.toString()),
          ),
          _btn(Icons.add),
        ],
      ),
    );
  }

  Widget _btn(IconData icon) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16),
      ),
    );
  }
}



