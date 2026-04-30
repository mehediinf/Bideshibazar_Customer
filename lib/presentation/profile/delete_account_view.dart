import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/user_provider.dart';
import 'dart:developer' as developer;

class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final TextEditingController _controller = TextEditingController();
  bool _canDelete = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          "Delete Account",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Warning Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffFFF9E6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xffF4B400),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xffF4B400),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text(
                      "If you delete your account, all of your account settings will be deleted, and some of our promotional offers will no longer be available to you.",
                      style: TextStyle(
                        color: Color(0xff856404),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Confirmation Text
            const Text(
              'To confirm, type "delete" in the box below.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            // Input Field
            TextField(
              controller: _controller,
              enabled: !_isLoading,
              onChanged: (value) {
                setState(() {
                  _canDelete = value.trim().toLowerCase() == "delete";
                });
              },
              decoration: InputDecoration(
                hintText: 'Type "delete"',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                filled: true,
                fillColor: _isLoading ? Colors.grey.shade100 : Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Delete Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_canDelete && !_isLoading) ? _onDeletePressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.shade200,
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
                  "DELETE ACCOUNT",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Additional Info
            Text(
              "This action cannot be undone. All your data will be permanently deleted.",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDeletePressed() async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          "Final Confirmation",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: const Text(
          "Are you absolutely sure you want to delete your account? This action is permanent and cannot be reversed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Yes, Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      developer.log('Starting Account Deletion Process', name: 'DELETE_ACCOUNT');

      final userProvider = context.read<UserProvider>();
      final token = userProvider.token;

      if (token == null || token.isEmpty) {
        throw Exception('User not logged in');
      }

      developer.log('Token found, calling delete API...', name: 'DELETE_ACCOUNT');

      final response = await ApiService().deleteAccount(token);

      final message = response['message'] ?? 'Account deleted successfully';

      if (response['success'] == true) {
        developer.log('Account deleted successfully', name: 'DELETE_ACCOUNT');

        // Clear all user data using logout method
        await userProvider.logout();

        if (mounted) {
          // Show success message
          _showToast(message, isError: false);

          // Wait a moment for the toast to be visible
          await Future.delayed(const Duration(seconds: 1));

          // Navigate to login/onboarding screen and clear all routes
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login', // or your onboarding route
                  (route) => false,
            );
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