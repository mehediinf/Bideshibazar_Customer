// lib/core/utils/cart_helper.dart

import 'package:flutter/material.dart';
import '../../presentation/auth/loginsystem_select_page.dart';
import '../../presentation/address/manage_address_view.dart';
import 'shared_prefs_helper.dart';

class CartHelper {

  static Future<bool> checkBeforeAddToCart(BuildContext context) async {
    // Step 1: Check Address first
    final hasAddress = await _checkAndPromptAddress(context);
    if (!hasAddress) {
      return false;
    }

    // Step 2: Check Login
    final isLoggedIn = await _checkAndPromptLogin(context);
    if (!isLoggedIn) {
      return false;
    }

    return true;
  }

  static Future<bool> _checkAndPromptAddress(BuildContext context) async {
    try {
      final savedAddress = await SharedPrefsHelper.getSelectedAddress();

      if (savedAddress == null) {
        // No address - show dialog
        if (context.mounted) {
          final shouldNavigate = await showAddressRequiredDialog(context);

          if (shouldNavigate) {
            // Navigate to address page
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageAddressView(),
              ),
            );

            // Check if address was set
            if (result != null) {
              if (context.mounted) {
                showSuccessMessage(context, 'Address set successfully!');
              }
              return true; // Address was set
            }
          }
        }
        return false; // Address not set
      }

      return true; // Address exists
    } catch (e) {
      debugPrint('Error checking address: $e');
      return false;
    }
  }

  static Future<bool> _checkAndPromptLogin(BuildContext context) async {
    try {
      final isLoggedIn = await SharedPrefsHelper.isLoggedIn();

      if (!isLoggedIn) {
        if (context.mounted) {
          final shouldNavigate = await showLoginRequiredDialog(context);

          if (shouldNavigate) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginSystemSelectPage(),
              ),
            );

            if (result == true) {
              if (context.mounted) {
                showSuccessMessage(context, 'Logged in successfully!');
              }
              return true;
            }
          }
        }
        return false; // User not logged in
      }

      return true; // User is logged in
    } catch (e) {
      debugPrint('❌ Error checking login: $e');
      return false;
    }
  }

  /// Show address required dialog
  static Future<bool> showAddressRequiredDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFFFF6B35),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Address Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Please set your delivery address first to add items to cart.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Set Address'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Show login required dialog
  static Future<bool> showLoginRequiredDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.login,
                color: Color(0xFFFF6B35),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Please login to add items to your cart.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Quick check without dialogs (for UI state)
  static Future<bool> canAddToCart() async {
    final hasAddress = await SharedPrefsHelper.getSelectedAddress() != null;
    final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
    return hasAddress && isLoggedIn;
  }

  /// Show success message
  static void showSuccessMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Show error message
  static void showErrorMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Show info message
  static void showInfoMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}