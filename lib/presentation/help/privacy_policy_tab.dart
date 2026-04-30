import 'package:flutter/material.dart';

class PrivacyPolicyTab extends StatelessWidget {
  const PrivacyPolicyTab({Key? key}) : super(key: key);

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
                      Icons.shield_outlined,
                      size: 48,
                      color: Color(0xFF0288D1),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: ${DateTime.now().year}',
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

            // Sections
            _buildSectionCard(
              number: '1',
              title: 'Information We Collect',
              content:
              'We collect personal data such as name, email, phone number, address, payment info, order history, and device information. Cookies and tracking data are also used.',
              icon: Icons.info_outline,
            ),

            _buildSectionCard(
              number: '2',
              title: 'How We Use Your Information',
              content:
              'We use your data to process orders, improve service, communicate updates, and ensure safety and fraud protection.',
              icon: Icons.settings_outlined,
            ),

            _buildSectionCard(
              number: '3',
              title: 'Cookies and Tracking Technologies',
              content:
              'Cookies help us run the site, analyze usage, and personalize experiences. You can manage cookies in your browser settings.',
              icon: Icons.track_changes_outlined,
            ),

            _buildSectionCard(
              number: '4',
              title: 'Data Sharing and Disclosure',
              content:
              'We do not sell your data. We may share with payment processors, delivery partners, or legal authorities when required.',
              icon: Icons.share_outlined,
            ),

            _buildSectionCard(
              number: '5',
              title: 'Managing Your Information',
              content:
              'You can update or delete your data anytime. To delete your account, use our Android/iOS app under Profile > Settings > Delete Account. Once deleted, it cannot be recovered.',
              icon: Icons.manage_accounts_outlined,
            ),

            _buildSectionCard(
              number: '6',
              title: 'Data Security',
              content:
              'We use SSL encryption, secure servers, and two-factor authentication to keep your data safe.',
              icon: Icons.security_outlined,
            ),

            _buildSectionCard(
              number: '7',
              title: 'Data Retention',
              content:
              'We retain your information only as long as necessary for business or legal purposes.',
              icon: Icons.storage_outlined,
            ),

            _buildSectionCard(
              number: '8',
              title: 'Children\'s Privacy',
              content:
              'Our service is not intended for children under 13. We do not knowingly collect data from minors.',
              icon: Icons.child_care_outlined,
            ),

            _buildSectionCard(
              number: '9',
              title: 'International Data Transfers',
              content:
              'Your data may be stored outside your country under strict protection standards.',
              icon: Icons.public_outlined,
            ),

            _buildSectionCard(
              number: '10',
              title: 'Changes to This Policy',
              content:
              'We may update this Privacy Policy from time to time. Major updates will be announced on our website or via email.',
              icon: Icons.update_outlined,
            ),

            _buildSectionCard(
              number: '11',
              title: 'Contact Us',
              content: 'For questions, contact us at info@bideshibazar.com',
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