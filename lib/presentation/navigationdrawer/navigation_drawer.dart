// lib/presentation/navigationdrawer/navigation_drawer.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/network/api_constants.dart';
import '../profile/profile_view.dart';
import '../auth/loginsystem_select_page.dart';
import '../complaint/file_complaint_view.dart';
import '../order_history/order_history_view.dart';
import '../safety_center/safety_center_view.dart';
import '../help/help_view.dart';
import '../favorites/favorites_view.dart';

class NavigationDrawerView extends StatefulWidget {
  const NavigationDrawerView({super.key});

  @override
  State<NavigationDrawerView> createState() => _NavigationDrawerViewState();
}

class _NavigationDrawerViewState extends State<NavigationDrawerView> {
  bool _isLoggedIn = false;
  String _userName = 'Guest';
  String? _userImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
      final userName = await SharedPrefsHelper.getUserName();
      final userImage = await SharedPrefsHelper.getUserImage();

      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _userName = userName ?? 'Guest';
          _userImage = userImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCustomerSupport(BuildContext context) async {
    Navigator.pop(context);
    const supportNumber = '+43 68864179877';
    const dialableNumber = '+4368864179877';
    final phoneUri = Uri(scheme: 'tel', path: dialableNumber);

    try {
      final launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showToast('Unable to open dialer for $supportNumber');
      }
    } catch (_) {
      _showToast('Unable to open dialer for $supportNumber');
    }
  }

  // Toast Helper Method
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildDrawerContent(context),
      ),
    );
  }

  Widget _buildDrawerContent(BuildContext context) {
    final isLoggedIn = _isLoggedIn;
    final userName = _userName;
    final userImage = _userImage;

    return Column(
      children: [
        // Header Section with Login & Language
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                spreadRadius: 0,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLoggedIn ? Colors.orange : Colors.grey,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isLoggedIn ? Colors.orange : Colors.grey)
                          .withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (isLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileView()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginSystemSelectPage(),
                        ),
                      );
                    }
                  },
                  child: isLoggedIn && userImage != null && userImage.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(
                            ApiConstants.getImageUrl(userImage),
                          ),
                          onBackgroundImageError: (_, __) {},
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.blue[700],
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Login Text or User Name
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (isLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileView()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginSystemSelectPage(),
                        ),
                      );
                    }
                  },
                  child: Text(
                    isLoggedIn ? userName : 'Login',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isLoggedIn ? Colors.black87 : Colors.orange,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Language Button
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showToast('Language selection coming soon');
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: const Text(
                    'ENG',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              _buildMenuItem(
                context: context,
                imagePath: 'assets/images/ic_club.png',
                title: 'BB Club',
                onTap: () {
                  Navigator.pop(context);
                  _showToast('BB Club feature coming soon');
                },
              ),

              // _buildMenuItem(
              //   context: context,
              //   icon: '🏪',
              //   title: 'All Store',
              //   onTap: () {
              //     Navigator.pop(context);
              //     _showToast('All Store feature coming soon');
              //   },
              // ),

              // _buildMenuItem(
              //   context: context,
              //   icon: '🎁',
              //   title: 'Offers',
              //   onTap: () {
              //     Navigator.pop(context);
              //     _showToast('Offers feature coming soon');
              //   },
              // ),
              _buildMenuItem(
                context: context,
                icon: '🎟️',
                title: 'Coupons',
                onTap: () {
                  Navigator.pop(context);
                  _showToast('Coupons feature coming soon');
                },
              ),

              _buildMenuItem(
                context: context,
                icon: '❤️',
                title: 'Favorites',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesView()),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey[200],
                ),
              ),

              _buildMenuItem(
                context: context,
                icon: '🔄',
                title: 'Order History',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderHistoryView()),
                  );
                },
              ),

              _buildMenuItem(
                context: context,
                icon: '🏅',
                title: 'Earn a Reward',
                onTap: () {
                  Navigator.pop(context);
                  _showToast('Earn a Reward feature coming soon');
                },
              ),

              _buildMenuItem(
                context: context,
                icon: '🎖️',
                title: 'Premium Care',
                onTap: () {
                  Navigator.pop(context);
                  _showToast('Premium Care feature coming soon');
                },
              ),

              _buildMenuItem(
                context: context,
                icon: '⚠️',
                title: 'File a complaint',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FileComplaintView(),
                    ),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey[200],
                ),
              ),

              _buildMenuItem(
                context: context,
                icon: '❓',
                title: 'Help',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpView()),
                  );
                },
                showTrailing: false,
              ),

              _buildMenuItem(
                context: context,
                icon: '📞',
                title: 'Customer Support',
                onTap: () {
                  _openCustomerSupport(context);
                },
                showTrailing: false,
              ),

              _buildMenuItem(
                context: context,
                icon: '🛡️',
                title: 'Safety Center',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SafetyCenterView()),
                  );
                },
                showTrailing: false,
              ),
            ],
          ),
        ),

        // Version Info at Bottom
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue[100]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.15),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/app_logo.jpg',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.store,
                        color: Colors.blue[700],
                        size: 20,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'v1.0',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    String? icon,
    String? imagePath,
    required String title,
    required VoidCallback onTap,
    bool showTrailing = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.blue.withValues(alpha: 0.08),
        highlightColor: Colors.blue.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Icon Container - Image বা Emoji
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[100]!, width: 1),
                ),
                child: imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          imagePath,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              icon ?? '📱',
                              style: const TextStyle(fontSize: 20),
                            );
                          },
                        ),
                      )
                    : Text(icon ?? '📱', style: const TextStyle(fontSize: 20)),
              ),

              const SizedBox(width: 12),

              // Title Text
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // Trailing Icon
              if (showTrailing)
                Icon(Icons.chevron_right, color: Colors.grey[350], size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
