// lib/presentation/widgets/step_indicator.dart

import 'package:flutter/material.dart';

class _StepIndicator extends StatelessWidget {
  const _StepIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _step(true, "Choice Product"),
          _line(),
          _step(true, "View Cart"),
          _line(),
          _step(false, "Checkout"),
        ],
      ),
    );
  }

  Widget _step(bool done, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: done ? Colors.green : Colors.grey.shade300,
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : const Text("3", style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: done ? Colors.blue : Colors.grey,
            fontWeight: done ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _line() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.grey.shade300,
      ),
    );
  }
}



