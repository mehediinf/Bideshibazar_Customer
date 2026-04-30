import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/user_provider.dart';
import 'dart:developer' as developer;

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _currentObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _currentController.text.isNotEmpty &&
        _newController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        _newController.text.length >= 6 &&
        _newController.text == _confirmController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          "Change Password",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Info Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Password must be at least 6 characters long",
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current Password
            _passwordField(
              controller: _currentController,
              hint: "Current Password",
              obscure: _currentObscure,
              onToggle: () {
                setState(() {
                  _currentObscure = !_currentObscure;
                });
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // New Password
            _passwordField(
              controller: _newController,
              hint: "New Password",
              obscure: _newObscure,
              onToggle: () {
                setState(() {
                  _newObscure = !_newObscure;
                });
              },
              onChanged: (_) => setState(() {}),
            ),

            // Password strength indicator
            if (_newController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _passwordStrengthIndicator(),
            ],

            const SizedBox(height: 12),

            // Confirm Password
            _passwordField(
              controller: _confirmController,
              hint: "Re-enter New Password",
              obscure: _confirmObscure,
              onToggle: () {
                setState(() {
                  _confirmObscure = !_confirmObscure;
                });
              },
              onChanged: (_) => setState(() {}),
            ),

            // Password match indicator
            if (_confirmController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _passwordMatchIndicator(),
            ],

            const SizedBox(height: 28),

            // Change Password Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isFormValid && !_isLoading) ? _onChangePassword : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.blue.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  "CHANGE PASSWORD",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffdceff1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: !_isLoading,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.orange,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _passwordStrengthIndicator() {
    final password = _newController.text;
    final hasMinLength = password.length >= 6;
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int strength = 0;
    if (hasMinLength) strength++;
    if (hasNumber) strength++;
    if (hasSpecialChar) strength++;

    Color color;
    String text;

    if (strength == 1) {
      color = Colors.red;
      text = "Weak";
    } else if (strength == 2) {
      color = Colors.orange;
      text = "Medium";
    } else {
      color = Colors.green;
      text = "Strong";
    }

    return Row(
      children: [
        const SizedBox(width: 20),
        Container(
          height: 4,
          width: 60,
          decoration: BoxDecoration(
            color: strength >= 1 ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          height: 4,
          width: 60,
          decoration: BoxDecoration(
            color: strength >= 2 ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          height: 4,
          width: 60,
          decoration: BoxDecoration(
            color: strength >= 3 ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _passwordMatchIndicator() {
    final match = _newController.text == _confirmController.text;

    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        children: [
          Icon(
            match ? Icons.check_circle : Icons.cancel,
            color: match ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            match ? "Passwords match" : "Passwords don't match",
            style: TextStyle(
              color: match ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onChangePassword() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      developer.log('Starting Password Change Process', name: 'CHANGE_PASSWORD');

      final userProvider = context.read<UserProvider>();
      final token = userProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('User not logged in');
      }

      developer.log('Token found, calling change password API...', name: 'CHANGE_PASSWORD');

      final response = await ApiService().changePassword(
        token,
        {
          'current_password': _currentController.text,
          'new_password': _newController.text,
          'new_password_confirmation': _confirmController.text,
        },
      );

      final message = response['message'] ?? 'Password changed successfully';

      if (response['success'] == true) {

        if (mounted) {
          // Show success message
          _showToast(message, isError: false);

          // Clear fields
          _currentController.clear();
          _newController.clear();
          _confirmController.clear();

          // Wait a moment then go back
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        _showToast(message, isError: true);
      }
    } catch (e, stackTrace) {

      _showToast(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
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
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}