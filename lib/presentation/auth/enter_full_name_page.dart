// lib/presentation/auth/enter_full_name_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/user_provider.dart';
import 'accept_terms_page.dart';

class EnterFullNamePage extends StatefulWidget {
  const EnterFullNamePage({super.key});

  @override
  State<EnterFullNamePage> createState() => _EnterFullNamePageState();
}

class _EnterFullNamePageState extends State<EnterFullNamePage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isExistingUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userProvider = context.read<UserProvider>();

    // Check if user already has a name
    if (userProvider.userName != null && userProvider.userName!.isNotEmpty) {
      setState(() {
        _nameController.text = userProvider.userName!;
        _isExistingUser = true;
      });
    }
  }

  Future<void> _submitName() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevent multiple clicks
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final userProvider = context.read<UserProvider>();
    final token = userProvider.token;

    // If no token, user must complete registration first
    if (token == null || token.isEmpty) {
      _showToast(
        'Please complete OTP verification first',
        isError: true,
      );
      return;
    }

    // Check if name is empty (mandatory field)
    if (name.isEmpty) {
      _showToast(
        'Name is required to continue',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call update profile API
      final response = await ApiService().updateProfile(
        token,
        {'name': name},
      );

      // Show API message
      final message = response['message'] ??
          (response['success'] == true
              ? 'Name saved successfully'
              : 'Failed to save name');

      _showToast(message, isError: response['success'] != true);

      // On success, update local data and navigate
      if (response['success'] == true) {
        // Update local user data
        await userProvider.updateUserProfile(name: name);

        if (mounted) {
          // Navigate to next page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AcceptTermsPage(),
            ),
          );
        }
      }
    } catch (e) {
      _showToast('Error: ${e.toString()}', isError: true);
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Disable back navigation
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Show message that they must complete name entry
        _showToast(
          'Please enter your name to continue',
          isError: true,
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFD6A3), // peach background
        body: SafeArea(
          child: Stack(
            children: [
              // Main Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        /// Illustration
                        Image.asset(
                          'assets/images/mobile_email_vector.png',
                          height: 280,
                        ),

                        const SizedBox(height: 30),

                        /// Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              /// Title
                              Text(
                                _isExistingUser
                                    ? 'Update Your Full Name'
                                    : 'Please Enter Your Full Name',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// Name Field
                              Container(
                                height: 54,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.name,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    if (value.trim().length < 2) {
                                      return 'Name must be at least 2 characters';
                                    }
                                    return null;
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Full Name',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    errorStyle: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 26),

                              /// NEXT Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryBlue,
                                        AppColors.primaryBlue.withOpacity(0.85),
                                      ],
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _submitName,
                                    child: _isLoading
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                        : Text(
                                      _isExistingUser ? 'NEXT' : 'NEXT',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
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
              ),

              // Back button removed - user cannot go back
            ],
          ),
        ),
      ),
    );
  }
}