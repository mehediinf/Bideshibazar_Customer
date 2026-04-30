// lib/presentation/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/providers/user_provider.dart';
import '../../data/models/request/login_request.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/services/apple_auth_service.dart';
import '../../core/utils/login_device_info.dart';
import 'forgot_password_page.dart';
import 'mobile_email_otp_login.dart';
import 'dart:developer' as developer;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool obscureText = true;
  bool rememberMe = true;
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool isAppleLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AppleAuthService _appleAuthService = AppleAuthService();

  bool _isAppleSignInAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAppleSignInAvailability();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //  CHECK APPLE SIGN-IN AVAILABILITY

  Future<void> _checkAppleSignInAvailability() async {
    final isAvailable = await _appleAuthService.isAvailable();
    if (mounted) {
      setState(() {
        _isAppleSignInAvailable = isAvailable;
      });
    }
    developer.log(
      ' Apple Sign-In available: $isAvailable',
      name: 'APPLE_CHECK',
    );
  }

  //  APPLE SIGN-IN HANDLER

  Future<void> _handleAppleSignIn() async {
    // Check availability first
    if (!_isAppleSignInAvailable) {
      _showToast('Apple Sign-In is not available on this device');
      return;
    }

    setState(() => isAppleLoading = true);

    try {
      developer.log(' Starting Apple Sign-In Flow', name: 'APPLE_FLOW');

      // Get FCM token (if available)
      FirebaseMessagingService? fcmService;
      String? fcmToken;

      try {
        fcmService = Provider.of<FirebaseMessagingService>(
          context,
          listen: false,
        );
        fcmToken = await fcmService.getCurrentToken();
        developer.log(
          ' FCM Token: ${fcmToken ?? "Not available"}',
          name: 'APPLE_FLOW',
        );
      } catch (e) {
        developer.log(
          ' FCM not available, continuing without it',
          name: 'APPLE_FLOW',
        );
      }

      final deviceInfo = await LoginDeviceInfoCollector.collect();

      // Sign in with Apple
      developer.log(' Initiating Apple Sign-In...', name: 'APPLE_FLOW');

      final appleResult = await _appleAuthService.signInWithApple();

      if (!appleResult['success']) {
        developer.log(
          ' Apple Sign-In failed: ${appleResult['message']}',
          name: 'APPLE_FLOW',
        );
        _showToast(appleResult['message']);
        return;
      }

      final String identityToken = appleResult['identityToken'];
      final String? userIdentifier = appleResult['userIdentifier'];
      final String? email = appleResult['email'];
      final String? fullName = appleResult['fullName'];

      developer.log(' Apple Sign-In successful!', name: 'APPLE_FLOW');
      developer.log(
        '   User ID: ${userIdentifier ?? "N/A"}',
        name: 'APPLE_FLOW',
      );
      developer.log('   Email: ${email ?? "N/A"}', name: 'APPLE_FLOW');
      developer.log('   Full Name: ${fullName ?? "N/A"}', name: 'APPLE_FLOW');

      // Send identity token to backend with correct parameters
      developer.log(' Sending token to backend...', name: 'APPLE_FLOW');

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
        developer.log(
          ' Backend login failed: ${loginResult['message']}',
          name: 'APPLE_FLOW',
        );
        _showToast(loginResult['message']);
        return;
      }

      // Save user data
      developer.log(' Saving user data...', name: 'APPLE_FLOW');

      final loginResponse = loginResult['data'];

      await context.read<UserProvider>().setUserData(
        token: loginResponse['token'],
        userId: loginResponse['user']['id'],
        userName: loginResponse['user']['name'],
        userEmail: loginResponse['user']['email'] ?? '',
        userPhone: loginResponse['user']['phone'] ?? '',
        userImage: loginResponse['user']['image'],
      );

      developer.log(' User data saved!', name: 'APPLE_FLOW');

      // Save FCM token to SharedPreferences
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await SharedPrefsHelper.saveFcmToken(fcmToken);
        developer.log(' FCM token saved to local storage', name: 'APPLE_FLOW');
      }

      // Sync FCM token with backend (if available)
      if (fcmToken != null && fcmToken.isNotEmpty && fcmService != null) {
        developer.log(' Syncing FCM token with backend...', name: 'APPLE_FLOW');

        final baseUrl = await SharedPrefsHelper.getBaseUrl();
        if (baseUrl != null) {
          try {
            await fcmService.sendTokenToBackend(
              baseUrl,
              loginResponse['token'],
            );
            developer.log(' FCM token synced successfully', name: 'APPLE_FLOW');
          } catch (e) {
            developer.log(
              ' FCM sync failed (non-critical): $e',
              name: 'APPLE_FLOW',
            );
          }
        }
      }

      developer.log(
        ' Apple Sign-In completed successfully!',
        name: 'APPLE_FLOW',
      );

      _showToast('Welcome ${loginResponse['user']['name']}!');

      // Navigate to home
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e, stackTrace) {
      developer.log(
        ' CRITICAL ERROR in Apple Sign-In Flow',
        name: 'APPLE_FLOW',
      );
      developer.log('   Error: $e', name: 'APPLE_FLOW');
      developer.log('   Stack: $stackTrace', name: 'APPLE_FLOW');

      _showToast('Apple Sign-In failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isAppleLoading = false);
      }
    }
  }

  // GOOGLE SIGN-IN HANDLER

  Future<void> _handleGoogleSignIn() async {
    setState(() => isGoogleLoading = true);

    try {
      developer.log(' Starting Google Sign-In Flow', name: 'GOOGLE_FLOW');

      // Get FCM token (if available)
      FirebaseMessagingService? fcmService;
      String? fcmToken;

      try {
        fcmService = Provider.of<FirebaseMessagingService>(
          context,
          listen: false,
        );
        fcmToken = await fcmService.getCurrentToken();
        developer.log(
          ' FCM Token: ${fcmToken ?? "Not available"}',
          name: 'GOOGLE_FLOW',
        );
      } catch (e) {
        developer.log(
          ' FCM not available, continuing without it',
          name: 'GOOGLE_FLOW',
        );
      }

      final deviceInfo = await LoginDeviceInfoCollector.collect();

      // Sign in with Google
      developer.log('Initiating Google Sign-In...', name: 'GOOGLE_FLOW');

      final googleResult = await _googleAuthService.signInWithGoogle();

      if (!googleResult['success']) {
        developer.log(
          ' Google Sign-In failed: ${googleResult['message']}',
          name: 'GOOGLE_FLOW',
        );
        _showToast(googleResult['message']);
        return;
      }

      final String idToken = googleResult['idToken'];
      developer.log(' Google Sign-In successful!', name: 'GOOGLE_FLOW');
      developer.log(
        '   User: ${googleResult['user']['name']}',
        name: 'GOOGLE_FLOW',
      );
      developer.log(
        '   Email: ${googleResult['user']['email']}',
        name: 'GOOGLE_FLOW',
      );

      // Send ID token to backend
      developer.log(' Sending token to backend...', name: 'GOOGLE_FLOW');

      final loginResult = await _googleAuthService.loginWithGoogleToken(
        idToken: idToken,
        fcmToken: fcmToken,
        deviceInfo: deviceInfo,
      );

      if (!loginResult['success']) {
        developer.log(
          ' Backend login failed: ${loginResult['message']}',
          name: 'GOOGLE_FLOW',
        );
        _showToast(loginResult['message']);
        return;
      }

      // Save user data
      developer.log(' Saving user data...', name: 'GOOGLE_FLOW');

      final loginResponse = loginResult['data'];

      await context.read<UserProvider>().setUserData(
        token: loginResponse['token'],
        userId: loginResponse['user']['id'],
        userName: loginResponse['user']['name'],
        userEmail: loginResponse['user']['email'] ?? '',
        userPhone: loginResponse['user']['phone'] ?? '',
        userImage: loginResponse['user']['image'],
      );

      developer.log(' User data saved!', name: 'GOOGLE_FLOW');

      //  Save FCM token to SharedPreferences
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await SharedPrefsHelper.saveFcmToken(fcmToken);
        developer.log('FCM token saved to local storage', name: 'GOOGLE_FLOW');
      }

      // Sync FCM token with backend (if available)
      if (fcmToken != null && fcmToken.isNotEmpty && fcmService != null) {
        developer.log(
          ' Syncing FCM token with backend...',
          name: 'GOOGLE_FLOW',
        );

        final baseUrl = await SharedPrefsHelper.getBaseUrl();
        if (baseUrl != null) {
          try {
            await fcmService.sendTokenToBackend(
              baseUrl,
              loginResponse['token'],
            );
            developer.log(
              ' FCM token synced successfully',
              name: 'GOOGLE_FLOW',
            );
          } catch (e) {
            developer.log(
              ' FCM sync failed (non-critical): $e',
              name: 'GOOGLE_FLOW',
            );
          }
        }
      }

      developer.log(
        ' Google Sign-In completed successfully!',
        name: 'GOOGLE_FLOW',
      );

      _showToast('Welcome ${loginResponse['user']['name']}!');

      // Navigate to home
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e, stackTrace) {
      developer.log(
        ' CRITICAL ERROR in Google Sign-In Flow',
        name: 'GOOGLE_FLOW',
      );
      developer.log('   Error: $e', name: 'GOOGLE_FLOW');
      developer.log('   Stack: $stackTrace', name: 'GOOGLE_FLOW');

      _showToast('Google Sign-In failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isGoogleLoading = false);
      }
    }
  }

  // REGULAR EMAIL/PASSWORD LOGIN
  Future<void> _handleLogin() async {
    // Validation
    if (_emailController.text.trim().isEmpty) {
      _showToast('Please enter your email');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showToast('Please enter your password');
      return;
    }

    // Email validation
    if (!_isValidEmail(_emailController.text.trim())) {
      _showToast('Please enter a valid email address');
      return;
    }

    setState(() => isLoading = true);

    try {
      developer.log(' Starting Login Process', name: 'LOGIN_FCM');

      // Try to get FCM Service from Provider (with error handling)
      FirebaseMessagingService? fcmService;
      String? fcmToken;

      try {
        fcmService = Provider.of<FirebaseMessagingService>(
          context,
          listen: false,
        );
        developer.log('FCM Service found from Provider', name: 'LOGIN_FCM');
      } catch (e) {
        developer.log(
          ' FCM Service not available in Provider',
          name: 'LOGIN_FCM',
        );
        developer.log('   Error: $e', name: 'LOGIN_FCM');
        developer.log(
          '   This is OK - continuing without FCM',
          name: 'LOGIN_FCM',
        );
        fcmService = null;
      }

      // Get FCM token before login (if service available)
      if (fcmService != null) {
        try {
          developer.log('Getting FCM token from service...', name: 'LOGIN_FCM');

          fcmToken = await fcmService.getCurrentToken();

          if (fcmToken != null && fcmToken.isNotEmpty) {
            developer.log(
              'FCM Token Retrieved Successfully!',
              name: 'LOGIN_FCM',
            );
            developer.log(
              'Token Length: ${fcmToken.length} characters',
              name: 'LOGIN_FCM',
            );
            developer.log(
              'Token Preview: ${fcmToken.substring(0, 30)}...',
              name: 'LOGIN_FCM',
            );
            developer.log('Full Token: $fcmToken', name: 'LOGIN_FCM');
          } else {
            developer.log('FCM token is NULL or EMPTY', name: 'LOGIN_FCM');
            developer.log('Trying to get token again...', name: 'LOGIN_FCM');

            // Try one more time
            await Future.delayed(const Duration(milliseconds: 500));
            fcmToken = await fcmService.getCurrentToken();

            if (fcmToken != null && fcmToken.isNotEmpty) {
              developer.log('FCM Token Retrieved on Retry!', name: 'LOGIN_FCM');
              developer.log('Full Token: $fcmToken', name: 'LOGIN_FCM');
            } else {
              developer.log(
                'Still no FCM token after retry',
                name: 'LOGIN_FCM',
              );
            }
          }
        } catch (e) {
          developer.log('Error getting FCM token: $e', name: 'LOGIN_FCM');
          developer.log(
            'Stack trace: ${StackTrace.current}',
            name: 'LOGIN_FCM',
          );
        }
      } else {
        developer.log(
          'FCM Service is NULL - cannot get token',
          name: 'LOGIN_FCM',
        );
      }

      developer.log('Creating Login Request', name: 'LOGIN_FCM');

      final deviceInfo = await LoginDeviceInfoCollector.collect();

      // Create login request with FCM token
      final request = LoginRequest.fromDeviceInfo(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fcmToken: fcmToken ?? '',
        guestId: null,
        deviceInfo: deviceInfo,
      );

      developer.log('Email: ${request.email}', name: 'LOGIN_FCM');
      developer.log(
        'Password: ${"*" * request.password.length}',
        name: 'LOGIN_FCM',
      );
      developer.log(
        'FCM Token being sent: ${fcmToken ?? "EMPTY"}',
        name: 'LOGIN_FCM',
      );

      if (fcmToken == null || fcmToken.isEmpty) {
        developer.log('WARNING: Sending EMPTY FCM token!', name: 'LOGIN_FCM');
      }

      developer.log(' Calling Login API...', name: 'LOGIN_FCM');

      // Call login API
      final result = await _authService.login(request);

      developer.log(' Login API Response Received', name: 'LOGIN_FCM');
      developer.log('   Success: ${result['success']}', name: 'LOGIN_FCM');

      if (result['success']) {
        final loginResponse = result['data'];

        developer.log(' Login Successful!', name: 'LOGIN_FCM');
        developer.log(' User: ${loginResponse.user.name}', name: 'LOGIN_FCM');
        developer.log(
          ' Auth Token: ${loginResponse.token.substring(0, 20)}...',
          name: 'LOGIN_FCM',
        );

        // Save user data
        await context.read<UserProvider>().setUserData(
          token: loginResponse.token,
          userId: loginResponse.user.id,
          userName: loginResponse.user.name,
          userEmail: loginResponse.user.email ?? '',
          userPhone: loginResponse.user.phone ?? '',
          userImage: loginResponse.user.image,
        );

        developer.log(' User data saved to Provider', name: 'LOGIN_FCM');

        // Save FCM token to SharedPreferences
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await SharedPrefsHelper.saveFcmToken(fcmToken);
          developer.log(
            'FCM token saved to SharedPreferences',
            name: 'LOGIN_FCM',
          );
        } else {
          developer.log(' No FCM token to save', name: 'LOGIN_FCM');
        }

        // Send FCM token to backend (backup)
        if (fcmToken != null && fcmToken.isNotEmpty && fcmService != null) {
          developer.log(' Sending FCM token to backend...', name: 'LOGIN_FCM');

          final baseUrl = await SharedPrefsHelper.getBaseUrl();
          developer.log(' Base URL: $baseUrl', name: 'LOGIN_FCM');

          if (baseUrl != null) {
            try {
              await fcmService.sendTokenToBackend(baseUrl, loginResponse.token);
              developer.log(
                ' FCM token synced with backend',
                name: 'LOGIN_FCM',
              );
            } catch (e) {
              developer.log(' Failed to sync FCM token: $e', name: 'LOGIN_FCM');
            }
          } else {
            developer.log(
              'Base URL is NULL - cannot send token',
              name: 'LOGIN_FCM',
            );
          }
        } else {
          developer.log(
            'Skipping backend sync - no token or service',
            name: 'LOGIN_FCM',
          );
          developer.log(
            '   FCM Token: ${fcmToken ?? "NULL"}',
            name: 'LOGIN_FCM',
          );
          developer.log(
            '   FCM Service: ${fcmService != null ? "Available" : "NULL"}',
            name: 'LOGIN_FCM',
          );
        }

        developer.log(
          ' Login Process Completed Successfully',
          name: 'LOGIN_FCM',
        );

        _showToast('Login successful!');

        // Navigate to home
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        developer.log('Login Failed: ${result['message']}', name: 'LOGIN_FCM');
        _showToast(result['message']);
      }
    } catch (e, stackTrace) {
      developer.log(' CRITICAL ERROR in Login Process', name: 'LOGIN_FCM');
      developer.log('   Error: $e', name: 'LOGIN_FCM');
      developer.log('   Stack: $stackTrace', name: 'LOGIN_FCM');
      _showToast('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_back.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          // Main Content
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: constraints.maxHeight * 0.15),

                          const Text(
                            'Welcome Back 👋',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2196F3),
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Login to continue shopping with BideshiBazar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 46),

                          _inputField(
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            hint: 'Email Address',
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 16),

                          _inputField(
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hint: 'Password',
                            isPassword: true,
                            suffix: IconButton(
                              icon: Icon(
                                obscureText
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() => obscureText = !obscureText);
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                activeColor: Colors.teal,
                                onChanged: (val) {
                                  setState(() => rememberMe = val!);
                                },
                              ),
                              const Text('Remember Me'),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Color(0xFF2196F3)),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: isLoading ? null : _handleLogin,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          Row(
                            children: const [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 22),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _socialIcon(
                                'assets/icons/logos_google.png',
                                onTap: isGoogleLoading
                                    ? null
                                    : _handleGoogleSignIn,
                                isLoading: isGoogleLoading,
                              ),
                              _socialIcon(
                                'assets/icons/logos_apple.png',
                                onTap: isAppleLoading
                                    ? null
                                    : _handleAppleSignIn,
                                isLoading: isAppleLoading,
                                isDisabled: !_isAppleSignInAvailable,
                              ),
                              _socialIcon('assets/icons/logos_facebook.png'),
                              _socialIcon('assets/icons/logos_email_phone.png'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Back Button
          Positioned(
            bottom: 24,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFE8F6F6),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54, fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.orange),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
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
    return GestureDetector(
      onTap: isDisabled
          ? null
          : (onTap ??
                () {
                  if (asset == 'assets/icons/logos_email_phone.png') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MobileEmailOtpLogin(),
                      ),
                    );
                  }
                }),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isLoading ? Colors.grey.shade200 : null,
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2196F3),
                      ),
                    ),
                  ),
                )
              : Image.asset(asset, height: 42, width: 42),
        ),
      ),
    );
  }
}
