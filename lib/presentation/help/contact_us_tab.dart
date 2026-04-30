import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsTab extends StatefulWidget {
  const ContactUsTab({Key? key}) : super(key: key);

  @override
  State<ContactUsTab> createState() => _ContactUsTabState();
}

class _ContactUsTabState extends State<ContactUsTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String message = _messageController.text.trim();

      final String recipient = 'info@bideshibazar.com';
      final String subject = Uri.encodeComponent('Contact Us Message from $name');
      final String body = Uri.encodeComponent(
          'Name: $name\nEmail: $email\n\nMessage:\n$message');

      final Uri emailUri = Uri.parse('mailto:$recipient?subject=$subject&body=$body');

      try {
        if (await canLaunchUrl(emailUri)) {
          await launchUrl(emailUri);
          // Clear fields after successful send
          _nameController.clear();
          _emailController.clear();
          _messageController.clear();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening email client...')),
            );
          }
        } else {
          throw 'Could not launch email client';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No email clients installed.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            const Text(
              'Send Us A Message',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 24),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Your Name',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0288D1)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Your Email',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0288D1)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Message Field
            TextFormField(
              controller: _messageController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Your Message',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0288D1)),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your message';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Send Button
            Center(
              child: ElevatedButton(
                onPressed: _sendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Send Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Divider
            const SizedBox(height: 32),
            Container(
              height: 1,
              color: const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 16),

            // Get in Touch Section
            const SizedBox(height: 32),
            const Text(
              '📬 Get in Touch',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0288D1),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'For any inquiries, feel free to reach out via email, phone, or visit our office. We\'re happy to help you!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF616161),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Office Info
            _buildInfoRow('📍', 'Our Office: Wien 1120, Austria'),
            const SizedBox(height: 12),

            _buildInfoRow('📞', 'Phone: +43 688 6417 9877'),
            const SizedBox(height: 12),

            _buildInfoRow('📧', 'Email: info@bideshibazar.com'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF37474F),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}