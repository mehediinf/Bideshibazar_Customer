// lib/presentation/auth/forgot_password_otp_verify_page.dart

import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import 'login_page.dart';

class ForgotPasswordOtpVerifyPage extends StatefulWidget {
  final String identifier;

  const ForgotPasswordOtpVerifyPage({
    super.key,
    required this.identifier,
  });

  @override
  State<ForgotPasswordOtpVerifyPage> createState() =>
      _ForgotPasswordOtpVerifyPageState();
}

class _ForgotPasswordOtpVerifyPageState
    extends State<ForgotPasswordOtpVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if passwords match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().resetPassword({
        'identifier': widget.identifier,
        'otp': _otpController.text.trim(),
        'new_password': _newPasswordController.text,
        'new_password_confirmation': _confirmPasswordController.text,
      });

      if (response['success'] == true) {
        _showMessage(
          response['message'] ?? 'Password reset successfully',
          isError: false,
        );

        // Navigate to login page after successful reset
        if (mounted) {
          // Pop all pages and go to login
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
          );
        }
      } else {
        _showMessage(
          response['message'] ?? 'Failed to reset password',
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

      /// AppBar
      appBar: AppBar(
        elevation: 1,
        foregroundColor: Colors.black,
        title: const Text(
          'Forgot Password OTP',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                /// Illustration
                Image.asset(
                  'assets/images/forgot_password_otp_vector.jpg',
                  height: 250,
                ),

                const SizedBox(height: 18),

                /// Description
                const Text(
                  'Please check your email or phone and enter your OTP, '
                      'new Password, and Confirmation Password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFC49A3A),
                    fontSize: 17,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 26),

                /// OTP Field
                _buildInputBox(
                  controller: _otpController,
                  icon: Icons.verified_outlined,
                  iconColor: Colors.teal,
                  hint: 'OTP',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter OTP';
                    }
                    if (value.trim().length != 6) {
                      return 'OTP must be 6 digits';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// New Password
                _buildInputBox(
                  controller: _newPasswordController,
                  icon: Icons.lock_outline,
                  iconColor: Colors.amber,
                  hint: 'New Password',
                  obscure: _obscureNewPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  suffix: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscureNewPassword = !_obscureNewPassword);
                    },
                  ),
                ),

                const SizedBox(height: 16),

                /// Confirm Password
                _buildInputBox(
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  iconColor: Colors.pink,
                  hint: 'Confirm Password',
                  obscure: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(
                              () => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                ),

                const SizedBox(height: 28),

                /// Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE29A),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.black87),
                      ),
                    )
                        : const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable Input Box
  Widget _buildInputBox({
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5D8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          border: InputBorder.none,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.red),
          ),
          errorStyle: const TextStyle(fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          hintText: hint,
          prefixIcon: Icon(icon, color: iconColor),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}