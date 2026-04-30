// lib/presentation/order_success/order_success_view.dart

import 'package:flutter/material.dart';

class OrderSuccessView extends StatelessWidget {
  final String? orderNumber;
  final String? userName;

  const OrderSuccessView({
    super.key,
    this.orderNumber,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button - force user to use our navigation buttons
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Wolt Delivery Animation Image
                        Container(
                          height: 250,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF87CEEB).withOpacity(0.3),
                                Colors.white,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/delivery_success.png',
                              height: 200,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback icon if image not found
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00CCBC).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Icon(
                                    Icons.delivery_dining,
                                    size: 100,
                                    color: Color(0xFF00CCBC),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Success Message
                        Text(
                          '${userName ?? 'Customer'}, your order has been',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          'successfully placed!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Order ID
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00CCBC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00CCBC).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Order ID: ${orderNumber ?? 'ORD00089'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00796B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Information Container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              // English
                              const Text(
                                'We are verifying your order. If the item is available, we will notify you via message about the next steps for payment. Kindly wait for our confirmation. Thank you!',
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Color(0xFF424242),
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 20),
                              Divider(color: Colors.grey.shade300),
                              const SizedBox(height: 20),

                              // Bengali
                              const Text(
                                'আমরা তোমার অর্ডার যাচাই করছি। যদি পণ্যটি স্টকে থাকে, তাহলে মেসেজ দিয়ে জানিয়ে দেবো কিভাবে পেমেন্ট করতে হবে। একটু অপেক্ষা করো, ধন্যবাদ!',
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Color(0xFF424242),
                                  fontFamily: 'HindSiliguri', // Use Bengali font if available
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 20),
                              Divider(color: Colors.grey.shade300),
                              const SizedBox(height: 20),

                              // German
                              const Text(
                                'Wir prüfen Ihre Bestellung. Sobald der Artikel verfügbar ist, benachrichtigen wir Sie per Nachricht über die weiteren Zahlungsschritte. Bitte warten Sie auf unsere Bestätigung.',
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Color(0xFF424242),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Buttons
                Column(
                  children: [
                    // Return to Shopping Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // This will preserve the existing HomeView state instead of creating new one
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Return To Shopping',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Return to Order View Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/orders');
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFD97706),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Return To Order View',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}