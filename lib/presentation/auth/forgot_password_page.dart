// lib/presentation/auth/forgot_password_page.dart

import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import 'forgot_password_otp_verify_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final identifier = _identifierController.text.trim();

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().forgotPassword({
        'identifier': identifier,
      });

      if (response['success'] == true) {
        _showMessage(
          response['message'] ?? 'OTP sent successfully',
          isError: false,
        );

        // Navigate to OTP verification page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ForgotPasswordOtpVerifyPage(
                identifier: identifier,
              ),
            ),
          );
        }
      } else {
        _showMessage(
          response['message'] ?? 'Failed to send OTP',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage(
        'Error: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        foregroundColor: Colors.black,
        title: const Text(
          'Forgot Password',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),

              /// Illustration
              Image.asset(
                'assets/images/forgot_password.jpg',
                height: 220,
              ),

              const SizedBox(height: 30),

              /// Description
              const Text(
                'Please Enter Your Phone Number or Email\nAddress To Receive a Verification Code.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              /// Input Field
              Container(
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter email or phone number';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    errorStyle: const TextStyle(fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(
                        Icons.email_outlined,
                        size: 22,
                        color: Colors.redAccent,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    hintText: 'Phone or Email Address',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Next Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE09A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                      : const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}