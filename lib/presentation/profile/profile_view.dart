// lib/presentation/profile/profile_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/providers/user_provider.dart';
import '../../core/network/api_constants.dart';
import '../../core/services/profile_service.dart';
import 'personal_information_view.dart';
import 'settings_view.dart';
import '../address/manage_address_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _picker = ImagePicker();
  bool _isUpdating = false;

  void _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<UserProvider>().logout();

      Fluttertoast.showToast(
        msg: 'Logged out successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
              (route) => false,
        );
      }
    }
  }

  Future<void> _handleImageUpdate() async {
    if (_isUpdating) return;

    // Show image source selection
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      // Pick image with iOS-specific settings
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      print('Image picked: ${pickedFile.path}');
      print('Image size: ${await pickedFile.length()} bytes');

      setState(() => _isUpdating = true);

      // Convert XFile to File and verify it exists
      final File imageFile = File(pickedFile.path);

      if (!await imageFile.exists()) {
        throw Exception('Image file not accessible');
      }

      // Upload image
      final result = await _profileService.updateProfileImage(imageFile);

      if (result['success']) {
        // Update UserProvider with new image
        if (mounted) {
          final user = result['user'];
          await context.read<UserProvider>().updateUserProfile(
            image: user['image'],
          );

          Fluttertoast.showToast(
            msg: result['message'],
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
          );
        }
      } else {
        if (mounted) {
          Fluttertoast.showToast(
            msg: result['message'] ?? 'Failed to update profile image',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
          );
        }
      }
    } on Exception catch (e) {
      print('Exception during image update: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: ${e.toString()}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print('Unexpected error during image update: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to update profile image: ${e.toString()}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showUserDetailsBottomSheet(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              'User Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // User Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: userProvider.userImage != null &&
                  userProvider.userImage!.isNotEmpty
                  ? NetworkImage(
                ApiConstants.getImageUrl(userProvider.userImage!),
              )
                  : null,
              onBackgroundImageError: userProvider.userImage != null
                  ? (_, __) {}
                  : null,
              child: userProvider.userImage == null ||
                  userProvider.userImage!.isEmpty
                  ? const Icon(
                Icons.person,
                size: 50,
                color: Colors.grey,
              )
                  : null,
            ),

            const SizedBox(height: 24),

            // User Details List
            _detailRow(
              icon: Icons.person,
              label: 'Name',
              value: userProvider.userName ?? 'N/A',
              context: context,
            ),

            if (userProvider.userEmail != null &&
                userProvider.userEmail!.isNotEmpty &&
                userProvider.userEmail!.contains('@') &&
                !userProvider.userEmail!.contains('noemail'))
              _detailRow(
                icon: Icons.email,
                label: 'Email',
                value: userProvider.userEmail!,
                context: context,
              ),

            if (userProvider.userPhone != null &&
                userProvider.userPhone!.isNotEmpty)
              _detailRow(
                icon: Icons.phone,
                label: 'Phone',
                value: userProvider.userPhone!,
                context: context,
              ),

            _detailRow(
              icon: Icons.badge,
              label: 'User ID',
              value: userProvider.userId?.toString() ?? 'N/A',
              context: context,
            ),

            const SizedBox(height: 32),

            // Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            color: Colors.grey.shade600,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              Fluttertoast.showToast(
                msg: 'Copied to clipboard',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final userName = userProvider.userName ?? 'Guest User';
          final userImage = userProvider.userImage;
          final displayContact = userProvider.displayContact;

          return Column(
            children: [
              const SizedBox(height: 12),

              // Profile Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: userImage != null && userImage.isNotEmpty
                              ? NetworkImage(
                            ApiConstants.getImageUrl(userImage),
                          )
                              : null,
                          onBackgroundImageError: userImage != null ? (_, __) {} : null,
                          child: userImage == null || userImage.isEmpty
                              ? const Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.grey,
                          )
                              : null,
                        ),
                        if (_isUpdating)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUpdating ? null : _handleImageUpdate,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: _isUpdating ? Colors.grey : Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayContact,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showUserDetailsBottomSheet(context, userProvider),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _item(
                icon: Icons.person_outline,
                title: "Personal Information",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PersonalInformationView(),
                    ),
                  );
                },
              ),

              _item(
                icon: Icons.home_outlined,
                title: "Manage Address",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageAddressView(),
                    ),
                  );
                },
              ),

              _item(
                icon: Icons.settings_outlined,
                title: "Settings",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsView(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              _item(
                icon: Icons.logout,
                title: "Logout",
                isLogout: true,
                onTap: () => _handleLogout(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isLogout ? Colors.red : Colors.black,
                ),
              ),
            ),
            if (!isLogout)
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}