// lib/features/profile/views/personal_information_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/network/api_service.dart';

class PersonalInformationView extends StatefulWidget {
  const PersonalInformationView({super.key});

  @override
  State<PersonalInformationView> createState() => _PersonalInformationViewState();
}

class _PersonalInformationViewState extends State<PersonalInformationView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailRegistered = false;
  bool _isMobileRegistered = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProvider = context.read<UserProvider>();

    _nameController.text = userProvider.userName ?? '';
    _emailController.text = userProvider.userEmail ?? '';
    _mobileController.text = userProvider.userPhone ?? '';

    // Check which field was used for registration
    final email = userProvider.userEmail ?? '';
    final phone = userProvider.userPhone ?? '';

    _isEmailRegistered = email.isNotEmpty &&
        email.contains('@') &&
        !email.toLowerCase().contains('noemail');

    _isMobileRegistered = phone.isNotEmpty &&
        email.toLowerCase().contains('noemail');
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final token = userProvider.token;

      if (token == null) {
        _showMessage('Please login first', isError: true);
        return;
      }

      final body = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
      };

      final response = await ApiService().updateProfile(token, body);

      if (response['success'] == true) {
        // Update local user data
        await userProvider.updateUserProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _mobileController.text.trim(),
        );

        _showMessage(response['message'] ?? 'Profile updated successfully');

        // Navigate back after successful update
        if (mounted) {
          Navigator.pop(context, true); 
        }
      } else {
        _showMessage(response['message'] ?? 'Failed to update profile', isError: true);
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
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
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Personal Information",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name Field (Always Editable)
              _label("Full name"),
              _buildTextField(
                controller: _nameController,
                hintText: "Enter your full name",
                enabled: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              // Email Field
              _label("Registered email"),
              _buildTextField(
                controller: _emailController,
                hintText: "Enter your email",
                enabled: !_isEmailRegistered, // Disabled if registered with email
                keyboardType: TextInputType.emailAddress,
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
              if (_isEmailRegistered)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    "ⓘ Email cannot be changed (used for registration)",
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),

              // Mobile Number Field
              _label("Mobile number"),
              _buildTextField(
                controller: _mobileController,
                hintText: "Enter your mobile number",
                enabled: !_isMobileRegistered, // Disabled if registered with phone
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid mobile number';
                  }
                  return null;
                },
              ),
              if (_isMobileRegistered)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    "ⓘ Mobile number cannot be changed (used for registration)",
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    "ⓘ Add your mobile number for better security",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 40),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2196F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _updateProfile,
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
                    "Profile Update",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 18),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      style: TextStyle(
        color: enabled ? Colors.black : Colors.grey,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xffF0F0F0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xff2196F3)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffE0E0E0)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        suffixIcon: !enabled
            ? const Icon(Icons.lock_outline, color: Colors.grey, size: 20)
            : null,
      ),
    );
  }
}