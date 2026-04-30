// lib/presentation/auth/email_otp_login_page.dart

import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import 'login_page.dart';
import 'email_otp_verify_login_page.dart';
import 'find_account.dart';

class EmailOtpLoginPage extends StatefulWidget {
  const EmailOtpLoginPage({super.key});

  @override
  State<EmailOtpLoginPage> createState() => _EmailOtpLoginPageState();
}

class _EmailOtpLoginPageState extends State<EmailOtpLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    // Validate email
    if (emailController.text.trim().isEmpty) {
      _showToast('Please enter your email', isError: true);
      return;
    }

    if (!_isValidEmail(emailController.text.trim())) {
      _showToast('Please enter a valid email address', isError: true);
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().sendEmailOtpForLogin(
        emailController.text.trim(),
      );

      // Show API message
      final message = response['message'] ?? 'OTP sent successfully';
      _showToast(message, isError: response['success'] != true);

      // Navigate to verify page on success
      if (response['success'] == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailOtpVerifyLoginPage(
              email: emailController.text.trim(),
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFD1A4),
              Color(0xFFFFE5CC),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  /// Illustration
                  Image.asset(
                    'assets/images/mobile_email_vector.png',
                    height: 220,
                  ),

                  const SizedBox(height: 20),

                  /// White Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Login with Email OTP",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          "Enter your email to receive OTP",
                          style: TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 20),

                        /// Email Field
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: "Enter email address",
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: const Color(0xFFF5F6FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// Send OTP Button
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0D8DDC),
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                                : const Text(
                              "Send OTP",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// Login Text
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(color: Colors.grey),
                              children: [
                                TextSpan(
                                  text: "Log In",
                                  style: TextStyle(
                                    color: Color(0xFF0D8DDC),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),

                  // Find Account
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FindAccountPage(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search, size: 22),
                        SizedBox(width: 6),
                        Text(
                          'Find my account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}