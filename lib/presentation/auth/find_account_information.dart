// lib/presentation/auth/find_account_information.dart

import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import 'find_account_otp_verify.dart';

class FindAccountInformationPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String identifier; // email or mobile

  const FindAccountInformationPage({
    super.key,
    required this.user,
    required this.identifier,
  });

  @override
  State<FindAccountInformationPage> createState() =>
      _FindAccountInformationPageState();
}

class _FindAccountInformationPageState
    extends State<FindAccountInformationPage> {
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().sendLoginOtp(widget.identifier);

      // Show API message
      final message = response['message'] ?? 'OTP sent successfully';
      _showToast(message, isError: response['success'] != true);

      // Navigate to OTP verify page on success
      if (response['success'] == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FindAccountOtpVerify(
              identifier: widget.identifier,
              userName: widget.user['name'] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showToast(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final name = user['name'] ?? 'User';
    final email = user['email'] ?? '';
    final phone = user['phone'] ?? '';

    // Determine contact display
    String contactInfo = '';
    if (email.isNotEmpty && email.contains('@')) {
      contactInfo = 'Email: $email';
    } else if (phone.isNotEmpty) {
      contactInfo = 'Phone: $phone';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFD2A6),
      body: SafeArea(
        child: Stack(
          children: [
            /// Main Content
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  children: [
                    /// Illustration
                    Image.asset(
                      'assets/images/mobile_email_vector.png',
                      height: 260,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 30),

                    /// White Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          /// Title
                          const Text(
                            "Please confirm this is your account.\n"
                                "To recover it, tap 'Continue.'",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A148C),
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// Divider
                          Container(
                            height: 3,
                            width: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A148C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),

                          const SizedBox(height: 24),

                          /// Account Name
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          /// Contact Info
                          if (contactInfo.isNotEmpty)
                            Text(
                              contactInfo,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),

                          const SizedBox(height: 28),

                          /// Continue Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF039BE5),
                                    Color(0xFF4FC3F7),
                                  ],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                    : const Text(
                                  "CONTINUE",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Back Button
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}