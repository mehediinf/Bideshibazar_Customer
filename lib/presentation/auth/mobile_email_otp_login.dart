// lib/presentation/auth/mobile_email_otp_login.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/apple_auth_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/login_device_info.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'mobile_email_otp_login_verify.dart';
import 'email_otp_login_page.dart';
import 'login_page.dart';
import 'find_account.dart';

class MobileEmailOtpLogin extends StatefulWidget {
  const MobileEmailOtpLogin({super.key});

  @override
  State<MobileEmailOtpLogin> createState() => _MobileEmailOtpLoginState();
}

class _MobileEmailOtpLoginState extends State<MobileEmailOtpLogin> {
  final _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isPhone = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isAppleSignInAvailable = false;

  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AppleAuthService _appleAuthService = AppleAuthService();

  @override
  void initState() {
    super.initState();
    _checkAppleSignInAvailability();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _checkAppleSignInAvailability() async {
    final isAvailable = await _appleAuthService.isAvailable();
    if (mounted) {
      setState(() {
        _isAppleSignInAvailable = isAvailable;
      });
    }
    // developer.log('Apple Sign-In available: $isAvailable', name: 'APPLE_CHECK');
  }

  Future<void> _handleAppleSignIn() async {
    if (!_isAppleSignInAvailable) {
      _showToast(
        'Apple Sign-In is not available on this device',
        isError: true,
      );
      return;
    }

    setState(() => _isAppleLoading = true);

    try {
      // developer.log('Starting Apple Sign-In Flow', name: 'APPLE_FLOW');

      FirebaseMessagingService? fcmService;
      String? fcmToken;

      try {
        fcmService = Provider.of<FirebaseMessagingService>(
          context,
          listen: false,
        );
        fcmToken = await fcmService.getCurrentToken();
        // developer.log('FCM Token: ${fcmToken ?? "Not available"}', name: 'APPLE_FLOW');
      } catch (e) {
        // developer.log('FCM not available, continuing without it', name: 'APPLE_FLOW');
      }

      final deviceInfo = await LoginDeviceInfoCollector.collect();

      // developer.log('Initiating Apple Sign-In...', name: 'APPLE_FLOW');

      final appleResult = await _appleAuthService.signInWithApple();

      if (!appleResult['success']) {
        // developer.log('Apple Sign-In failed: ${appleResult['message']}', name: 'APPLE_FLOW');
        _showToast(appleResult['message'], isError: true);
        return;
      }

      final String identityToken = appleResult['identityToken'];
      final String? userIdentifier = appleResult['userIdentifier'];
      final String? email = appleResult['email'];
      final String? fullName = appleResult['fullName'];

      // developer.log('Apple Sign-In successful!', name: 'APPLE_FLOW');
      // developer.log('  User ID: ${userIdentifier ?? "N/A"}', name: 'APPLE_FLOW');
      // developer.log('  Email: ${email ?? "N/A"}', name: 'APPLE_FLOW');
      // developer.log('  Full Name: ${fullName ?? "N/A"}', name: 'APPLE_FLOW');

      // developer.log('Sending token to backend...', name: 'APPLE_FLOW');

      final loginResult = await _appleAuthService.loginWithAppleToken(
        identityToken: identityToken,
        userIdentifier: userIdentifier,
        email: email,
        fullName: fullName,
        guestId: '',
        fcmToken: fcmToken,
        deviceInfo: deviceInfo,
      );

      if (!loginResult['success']) {
        // developer.log('Backend login failed: ${loginResult['message']}', name: 'APPLE_FLOW');
        _showToast(loginResult['message'], isError: true);
        return;
      }

      // developer.log('Saving user data...', name: 'APPLE_FLOW');

      final loginResponse = loginResult['data'];

      await context.read<UserProvider>().setUserData(
        token: loginResponse['token'],
        userId: loginResponse['user']['id'],
        userName: loginResponse['user']['name'],
        userEmail: loginResponse['user']['email'] ?? '',
        userPhone: loginResponse['user']['phone'] ?? '',
        userImage: loginResponse['user']['image'],
      );

      // developer.log('User data saved!', name: 'APPLE_FLOW');

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await SharedPrefsHelper.saveFcmToken(fcmToken);
        // developer.log('FCM token saved to local storage', name: 'APPLE_FLOW');
      }

      if (fcmToken != null && fcmToken.isNotEmpty && fcmService != null) {
        // developer.log('Syncing FCM token with backend...', name: 'APPLE_FLOW');

        final baseUrl = await SharedPrefsHelper.getBaseUrl();
        if (baseUrl != null) {
          try {
            await fcmService.sendTokenToBackend(
              baseUrl,
              loginResponse['token'],
            );
            // developer.log('FCM token synced successfully', name: 'APPLE_FLOW');
          } catch (e) {
            // developer.log('FCM sync failed (non-critical): $e', name: 'APPLE_FLOW');
          }
        }
      }

      // developer.log('Apple Sign-In completed successfully!', name: 'APPLE_FLOW');

      _showToast('Welcome ${loginResponse['user']['name']}!', isError: false);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      // developer.log('CRITICAL ERROR in Apple Sign-In Flow', name: 'APPLE_FLOW');
      // developer.log('  Error: $e', name: 'APPLE_FLOW');

      _showToast('Apple Sign-In failed. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isAppleLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      // developer.log('Starting Google Sign-In Flow', name: 'GOOGLE_FLOW');

      FirebaseMessagingService? fcmService;
      String? fcmToken;

      try {
        fcmService = Provider.of<FirebaseMessagingService>(
          context,
          listen: false,
        );
        fcmToken = await fcmService.getCurrentToken();
        // developer.log('FCM Token: ${fcmToken ?? "Not available"}', name: 'GOOGLE_FLOW');
      } catch (e) {
        // developer.log('FCM not available, continuing without it', name: 'GOOGLE_FLOW');
      }

      final deviceInfo = await LoginDeviceInfoCollector.collect();

      // developer.log('Initiating Google Sign-In...', name: 'GOOGLE_FLOW');

      final googleResult = await _googleAuthService.signInWithGoogle();

      if (!googleResult['success']) {
        // developer.log('Google Sign-In failed: ${googleResult['message']}', name: 'GOOGLE_FLOW');
        _showToast(googleResult['message'], isError: true);
        return;
      }

      final String idToken = googleResult['idToken'];
      // developer.log('Google Sign-In successful!', name: 'GOOGLE_FLOW');
      // developer.log('  User: ${googleResult['user']['name']}', name: 'GOOGLE_FLOW');
      // developer.log('  Email: ${googleResult['user']['email']}', name: 'GOOGLE_FLOW');

      // developer.log('Sending token to backend...', name: 'GOOGLE_FLOW');

      final loginResult = await _googleAuthService.loginWithGoogleToken(
        idToken: idToken,
        fcmToken: fcmToken,
        deviceInfo: deviceInfo,
      );

      if (!loginResult['success']) {
        // developer.log('Backend login failed: ${loginResult['message']}', name: 'GOOGLE_FLOW');
        _showToast(loginResult['message'], isError: true);
        return;
      }

      // developer.log('Saving user data...', name: 'GOOGLE_FLOW');

      final loginResponse = loginResult['data'];

      await context.read<UserProvider>().setUserData(
        token: loginResponse['token'],
        userId: loginResponse['user']['id'],
        userName: loginResponse['user']['name'],
        userEmail: loginResponse['user']['email'] ?? '',
        userPhone: loginResponse['user']['phone'] ?? '',
        userImage: loginResponse['user']['image'],
      );

      // developer.log('User data saved!', name: 'GOOGLE_FLOW');

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await SharedPrefsHelper.saveFcmToken(fcmToken);
        // developer.log('FCM token saved to local storage', name: 'GOOGLE_FLOW');
      }

      if (fcmToken != null && fcmToken.isNotEmpty && fcmService != null) {
        // developer.log('Syncing FCM token with backend...', name: 'GOOGLE_FLOW');

        final baseUrl = await SharedPrefsHelper.getBaseUrl();
        if (baseUrl != null) {
          try {
            await fcmService.sendTokenToBackend(
              baseUrl,
              loginResponse['token'],
            );
            // developer.log('FCM token synced successfully', name: 'GOOGLE_FLOW');
          } catch (e) {
            // developer.log('FCM sync failed (non-critical): $e', name: 'GOOGLE_FLOW');
          }
        }
      }

      // developer.log('Google Sign-In completed successfully!', name: 'GOOGLE_FLOW');

      _showToast('Welcome ${loginResponse['user']['name']}!', isError: false);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      // developer.log('CRITICAL ERROR in Google Sign-In Flow', name: 'GOOGLE_FLOW');
      // developer.log('  Error: $e', name: 'GOOGLE_FLOW');

      _showToast('Google Sign-In failed. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Remove all non-digit characters for validation
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 10;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return;

    final input = _inputController.text.trim();

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> response;

      if (isPhone) {
        response = await ApiService().sendPhoneOtp({'mobile': input});
      } else {
        response = await ApiService().sendEmailOtp({'email': input});
      }

      final message =
          response['message'] ??
          (response['success'] == true
              ? 'OTP sent successfully'
              : 'Failed to send OTP');

      _showToast(message, isError: response['success'] != true);

      if (response['success'] == true) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MobileEmailOtpLoginVerify(contact: input, isPhone: isPhone),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),

              // Top Illustration
              Image.asset('assets/images/mobile_email_vector.png', height: 250),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPhone
                            ? 'Login with Phone Number'
                            : 'Login with Email',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        isPhone
                            ? 'Enter your phone number to receive OTP'
                            : 'Enter your email to receive OTP',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            // Prefix for phone
                            if (isPhone) ...[
                              const Text(
                                '🇦🇹 +43',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                            ],

                            Expanded(
                              child: TextFormField(
                                controller: _inputController,
                                keyboardType: isPhone
                                    ? TextInputType.phone
                                    : TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return isPhone
                                        ? 'Please enter phone number'
                                        : 'Please enter email';
                                  }

                                  if (isPhone && !_isValidPhone(value)) {
                                    return 'Please enter valid phone number';
                                  }

                                  if (!isPhone && !_isValidEmail(value)) {
                                    return 'Please enter valid email';
                                  }

                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: isPhone
                                      ? 'Enter phone number'
                                      : 'Enter email address',
                                  border: InputBorder.none,
                                  errorStyle: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),

                            // Toggle Icon
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isPhone = !isPhone;
                                  _inputController.clear();
                                });
                              },
                              child: Icon(
                                isPhone
                                    ? Icons.email_outlined
                                    : Icons.phone_outlined,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isLoading ? null : _sendOtp,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Send OTP',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialIcon(
                    'assets/icons/logos_google.png',
                    onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
                    isLoading: _isGoogleLoading,
                  ),
                  _socialIcon(
                    'assets/icons/logos_apple.png',
                    onTap: _isAppleLoading ? null : _handleAppleSignIn,
                    isLoading: _isAppleLoading,
                    isDisabled: !_isAppleSignInAvailable,
                  ),
                  _socialIcon('assets/icons/logos_facebook.png'),
                  _socialIcon(
                    'assets/icons/logos_email.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmailOtpLoginPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 64),

              // Find Account
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FindAccountPage()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.search, size: 22),
                    SizedBox(width: 6),
                    Text(
                      'Find my account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(
    String asset, {
    VoidCallback? onTap,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: isLoading ? Colors.grey.shade200 : Colors.white,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue,
                      ),
                    ),
                  )
                : Image.asset(asset, height: 42),
          ),
        ),
      ),
    );
  }
}
