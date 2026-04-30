// lib/presentation/shop_checkout/shopping_bag_view.dart

import 'package:flutter/material.dart';

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

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                CartProductItem(
                  image: "assets/images/muri.png",
                  title: "Bangladeshi Puffed Rice Atka 500g",
                  price: 2.75,
                  quantity: 2,
                  unit: "0.50 Piece",
                ),
                CartProductItem(
                  image: "assets/images/pg.png",
                  title: "Original PG Tips 80 Tea Bag",
                  price: 6.60,
                  quantity: 1,
                  unit: "0.30 Piece",
                ),
              ],
            ),
          ),

          _FreeDeliveryBanner(),

          _CheckoutButton(total: 12.10),
        ],
      ),
    );
  }
}
