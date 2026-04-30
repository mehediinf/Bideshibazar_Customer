import 'package:flutter/material.dart';

class OurStoryTab extends StatelessWidget {
  const OurStoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our Story',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bideshibazar is an online platform based in Austria, built to serve the diverse needs of international communities. '
                'We believe that time is precious, and accessing familiar, essential products from one\'s home country should never be a struggle.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'That\'s why we created Bideshibazar – to help people living in Austria easily shop for authentic groceries, household items, '
                'and cultural essentials, all delivered to their doorstep with care.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Our goal is to bridge the gap between continents, cultures, and cuisines through technology and trust. '
                'We are constantly evolving and committed to improving the lives of our customers through efficient service, '
                'product variety, and user-friendly experiences.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'If you have suggestions or want to contribute to our journey, please reach out to us at info@bideshibazar.com.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}