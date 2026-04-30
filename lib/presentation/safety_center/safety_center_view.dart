//lib/presentation/safety_center/safety_center_view.dart

import 'package:flutter/material.dart';

class SafetyCenterView extends StatelessWidget {
  const SafetyCenterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Safety Center',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title Section
            const Text(
              'How We Ensure Your',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Safety',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Safety Features List
            _buildSafetyFeature(
              icon: Icons.check_circle,
              title: 'Verify Delivery Associates',
              description:
              'We carefully verify all our Delivery Associates and provide ongoing training to ensure safety and professionalism.',
            ),
            const SizedBox(height: 16),

            _buildSafetyFeature(
              icon: Icons.check_circle,
              title: 'Real-Time Tracking',
              description:
              'We ensure your security with real-time tracking, so you always know where your delivery is and who\'s bringing it.\n*Currently available for selected areas',
            ),
            const SizedBox(height: 16),

            _buildSafetyFeature(
              icon: Icons.check_circle,
              title: 'Continuous Monitoring',
              description:
              'We closely track all deliveries to spot and address any irregularities quickly.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
