// lib/presentation/auth/mobile_email_otp_login.dart

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
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

  bool get _isIos => !kIsWeb && Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (_isIos) {
      _checkAppleSignInAvailability();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _checkAppleSignInAvailability() async {
    if (!_isIos) {
      if (mounted) {
        setState(() {
          _isAppleSignInAvailable = false;
        });
      }
      return;
    }

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

  static bool _isTabletLayout(Size size) => size.shortestSide >= 600;

  static bool _isWideTabletLayout(Size size) =>
      _isTabletLayout(size) && size.width >= 840;

  Widget _illustration(double height) {
    return Image.asset(
      'assets/images/mobile_email_vector.png',
      height: height,
      fit: BoxFit.contain,
    );
  }

  Widget _loginCard({required bool isTablet}) {
    final titleSize = isTablet ? 20.0 : 18.0;
    final subtitleSize = isTablet ? 14.0 : 13.0;
    final fieldHeight = isTablet ? 58.0 : 54.0;
    final buttonHeight = isTablet ? 54.0 : 50.0;
    final cardPadding = isTablet ? 26.0 : 22.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPhone ? 'Login with Phone Number' : 'Login with Email',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            isPhone
                ? 'Enter your phone number to receive OTP'
                : 'Enter your email to receive OTP',
            style: TextStyle(
              fontSize: subtitleSize,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: isTablet ? 22 : 18),
          Container(
            height: fieldHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                if (isPhone) ...[
                  Text(
                    '🇦🇹 +43',
                    style: TextStyle(fontSize: isTablet ? 17 : 16),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextFormField(
                    key: ValueKey<bool>(isPhone),
                    controller: _inputController,
                    keyboardType: isPhone
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: !isPhone,
                    autofillHints: isPhone
                        ? const [AutofillHints.telephoneNumber]
                        : const [AutofillHints.email],
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
                      errorStyle: TextStyle(fontSize: isTablet ? 12 : 11),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      isPhone = !isPhone;
                      _inputController.clear();
                    });
                  },
                  child: Icon(
                    isPhone ? Icons.email_outlined : Icons.phone_outlined,
                    color: AppColors.primaryBlue,
                    size: isTablet ? 26 : 24,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isTablet ? 24 : 22),
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: isTablet ? 16 : 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(fontSize: isTablet ? 14 : 13),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: Text(
                  'Log In',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialRow({required bool isTablet}) {
    final iconPad = isTablet ? 18.0 : 14.0;
    final avatarR = isTablet ? 32.0 : 28.0;
    final imgH = isTablet ? 46.0 : 42.0;

    Widget wrapSocial(
      String asset, {
      VoidCallback? onTap,
      bool isLoading = false,
      bool isDisabled = false,
    }) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: iconPad),
        child: GestureDetector(
          onTap: isDisabled ? null : onTap,
          child: Opacity(
            opacity: isDisabled ? 0.4 : 1.0,
            child: CircleAvatar(
              radius: avatarR,
              backgroundColor:
                  isLoading ? Colors.grey.shade200 : Colors.white,
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
                  : Image.asset(asset, height: imgH),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        wrapSocial(
          'assets/icons/logos_google.png',
          onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
          isLoading: _isGoogleLoading,
        ),
        if (_isIos)
          wrapSocial(
            'assets/icons/logos_apple.png',
            onTap: _isAppleLoading ? null : _handleAppleSignIn,
            isLoading: _isAppleLoading,
            isDisabled: !_isAppleSignInAvailable,
          ),
        wrapSocial('assets/icons/logos_facebook.png'),
        wrapSocial(
          'assets/icons/logos_email.png',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmailOtpLoginPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _findAccountLink({required bool isTablet}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FindAccountPage()),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: isTablet ? 24 : 22),
          const SizedBox(width: 6),
          Text(
            'Find my account',
            style: TextStyle(
              fontSize: isTablet ? 17 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final tablet = _isTabletLayout(size);
    final wideTablet = _isWideTabletLayout(size);

    final horizontalInset = tablet ? 32.0 : 20.0;
    final verticalInset = tablet ? 20.0 : 12.0;

    final imageHeight = wideTablet
        ? (size.height * 0.38).clamp(220.0, 360.0)
        : tablet
            ? (size.height * 0.22).clamp(140.0, 200.0)
            : (size.height * 0.175).clamp(96.0, 165.0);

    final maxCardWidth = tablet ? 520.0 : double.infinity;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final body = wideTablet
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Center(
                                child: _illustration(imageHeight),
                              ),
                            ),
                            SizedBox(width: tablet ? 28 : 16),
                            Expanded(
                              flex: 6,
                              child: Align(
                                alignment: Alignment.center,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 480),
                                  child: _loginCard(isTablet: true),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: tablet ? 36 : 28),
                        _socialRow(isTablet: tablet),
                        SizedBox(height: tablet ? 28 : 20),
                        _findAccountLink(isTablet: tablet),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: tablet ? 12 : 8),
                        Center(child: _illustration(imageHeight)),
                        SizedBox(height: tablet ? 24 : 16),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxCardWidth),
                            child: _loginCard(isTablet: tablet),
                          ),
                        ),
                        SizedBox(height: tablet ? 32 : 24),
                        _socialRow(isTablet: tablet),
                        SizedBox(height: tablet ? 28 : 20),
                        _findAccountLink(isTablet: tablet),
                      ],
                    );

              return ListView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  verticalInset,
                  horizontalInset,
                  verticalInset + bottomInset + 8,
                ),
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: body,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
