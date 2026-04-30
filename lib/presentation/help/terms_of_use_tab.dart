import 'package:flutter/material.dart';

class TermsOfUseTab extends StatelessWidget {
  const TermsOfUseTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: Color(0xFF0288D1),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Terms of Use',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Effective: ${DateTime.now().year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // All Sections
            _buildSectionCard(
              number: '1',
              title: 'Acceptance of Terms',
              content:
              'Welcome to Bideshi Bazar. By using our app or website, you agree to these Terms of Use and all related policies. If you disagree, please do not use our services.',
              icon: Icons.check_circle_outline,
            ),

            _buildSectionCard(
              number: '2',
              title: 'Eligibility',
              content:
              'You must be 16+ or use the app with parental supervision. We currently serve selected locations within Austria only.',
              icon: Icons.verified_user_outlined,
            ),

            _buildSectionCard(
              number: '3',
              title: 'Account Registration and Security',
              content:
              'You are responsible for keeping your login details safe. Notify us of any unauthorized use.',
              icon: Icons.lock_outline,
            ),

            _buildSectionCard(
              number: '4',
              title: 'Use of the Platform',
              content:
              'Use the platform only for legal purposes. Do not use bots or disrupt our services.',
              icon: Icons.computer_outlined,
            ),

            _buildSectionCard(
              number: '5',
              title: 'Orders and Sales',
              content:
              'Placing an order is an offer to buy. The contract is formed when the order is delivered and accepted.',
              icon: Icons.shopping_cart_outlined,
            ),

            _buildSectionCard(
              number: '6',
              title: 'Pricing and Payments',
              content:
              'Prices include VAT. Errors in pricing may result in cancellation. Payments can be made via accepted methods.',
              icon: Icons.payment_outlined,
            ),

            _buildSectionCard(
              number: '7',
              title: 'Delivery',
              content:
              'We deliver to selected addresses. Risk transfers to you once accepted.',
              icon: Icons.local_shipping_outlined,
            ),

            _buildSectionCard(
              number: '8',
              title: 'Returns and Refunds',
              content:
              'Returns must comply with our Return Policy. Refunds are processed within the defined timeline.',
              icon: Icons.keyboard_return_outlined,
            ),

            _buildSectionCard(
              number: '9',
              title: 'Intellectual Property',
              content:
              'All content belongs to or is licensed by Bideshi Bazar e.U. Do not copy without permission.',
              icon: Icons.copyright_outlined,
            ),

            _buildSectionCard(
              number: '10',
              title: 'Privacy',
              content: 'Use of the app is governed by our Privacy Policy.',
              icon: Icons.privacy_tip_outlined,
            ),

            _buildSectionCard(
              number: '11',
              title: 'Limitation of Liability',
              content:
              'We are not liable for indirect or incidental damages.',
              icon: Icons.warning_amber_outlined,
            ),

            _buildSectionCard(
              number: '12',
              title: 'Changes to Terms',
              content: 'Terms may change. Continued use means acceptance.',
              icon: Icons.update_outlined,
            ),

            _buildSectionCard(
              number: '13',
              title: 'Termination',
              content: 'We may terminate your access for any breach of terms.',
              icon: Icons.cancel_outlined,
            ),

            _buildSectionCard(
              number: '14',
              title: 'Governing Law',
              content: 'These Terms are governed by the laws of Austria.',
              icon: Icons.gavel_outlined,
            ),

            _buildSectionCard(
              number: '15',
              title: 'Contact',
              content:
              'info@bideshibazar.com | +43 68864179877 | Wien, Austria.',
              icon: Icons.contact_mail_outlined,
              isLast: true,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required String content,
    required IconData icon,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Icon and Title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0288D1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF0288D1),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$number. $title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0288D1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF444444),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}