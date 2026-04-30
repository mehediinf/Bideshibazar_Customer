// lib/presentation/auth/find_account.dart

import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import 'find_account_information.dart';

class FindAccountPage extends StatefulWidget {
  const FindAccountPage({super.key});

  @override
  State<FindAccountPage> createState() => _FindAccountPageState();
}

class _FindAccountPageState extends State<FindAccountPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _findAccount() async {
    final input = _controller.text.trim();

    if (input.isEmpty) {
      _showToast('Please enter your email or mobile number', isError: true);
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().findAccount(input);

      // Show API message
      final message = response['message'] ?? 'Account found';
      _showToast(message, isError: response['success'] != true);

      // Navigate to information page on success
      if (response['success'] == true && response['user'] != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FindAccountInformationPage(
              user: response['user'],
              identifier: input,
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFD2A6),
      body: SafeArea(
        child: Stack(
          children: [
            /// Back Button (Bottom Left)
            Positioned(
              left: 16,
              bottom: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            /// Main Content (Top + Center)
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/mobile_email_vector.png',
                      height: 260,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 24),

                    /// White Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          /// Title
                          const Text(
                            "Find Your Email/Mobile\nAccount",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Input Field
                          TextField(
                            controller: _controller,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: "Enter your phone or email",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Find Account Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: DecoratedBox(
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
                                onPressed: _isLoading ? null : _findAccount,
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
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                    : const Text(
                                  "Find Account",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }
}