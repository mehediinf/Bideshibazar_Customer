import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CareerTab extends StatelessWidget {
  const CareerTab({Key? key}) : super(key: key);

  Future<void> _openLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Join Bideshi Bazar Family',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD84315),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'At Bideshi Bazar, you\'re more than just your job title — you\'re a vital part of a growing e-commerce platform in Austria, helping connect communities to quality groceries. We aim to serve the Bangladeshi community with pride and care.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF444444),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Explore Our Vision',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0288D1),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Discover how Bideshi Bazar is transforming the grocery shopping experience for the Bangladeshi community in Austria. From dedicated shop owners to our smart delivery team, every part of our journey is driven by the goal to make quality, affordable essentials accessible — with care, efficiency, and cultural connection.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF444444),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Perks of Being a Team Member',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF5722),
            ),
          ),
          const SizedBox(height: 16),

          _buildPerkItem(
            icon: Icons.credit_card,
            text: 'Advance grocery credit for monthly essentials.',
          ),
          const SizedBox(height: 12),

          _buildPerkItem(
            icon: Icons.trending_up,
            text: 'Performance-based increments and recognition.',
          ),
          const SizedBox(height: 12),

          _buildPerkItem(
            icon: Icons.emoji_emotions,
            text: 'Friendly work environment that thrives on collaboration and joy.',
          ),
          const SizedBox(height: 24),

          const Text(
            '🎓 Development through experience',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E2723),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Learn and grow while working on real-world challenges every day.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF616161),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(
                'assets/images/instagram.png',
                    () => _openLink('https://www.instagram.com/bideshibazareu/'),
              ),
              const SizedBox(width: 16),
              _buildSocialIcon(
                'assets/images/facebook.png',
                    () => _openLink('https://www.facebook.com/bidesibazar/'),
              ),
              const SizedBox(width: 16),
              _buildSocialIcon(
                'assets/images/youtube.png',
                    () => _openLink('https://www.youtube.com/@BideshiBazar4'),
              ),
              const SizedBox(width: 16),
              _buildSocialIcon(
                'assets/images/twitter.png',
                    () => _openLink('https://x.com/BideshiBazar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPerkItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFF5722).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFFFF5722),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          assetPath,
          width: 32,
          height: 32,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.public,
              size: 32,
              color: Colors.grey[400],
            );
          },
        ),
      ),
    );
  }
}