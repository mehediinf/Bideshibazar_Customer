// lib/presentation/auth/email_otp_verify_login_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/utils/login_device_info.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'enter_full_name_page.dart';
import 'dart:developer' as developer;

class EmailOtpVerifyLoginPage extends StatefulWidget {
  final String email;

  const EmailOtpVerifyLoginPage({super.key, required this.email});

  @override
  State<EmailOtpVerifyLoginPage> createState() =>
      _EmailOtpVerifyLoginPageState();
}

class _EmailOtpVerifyLoginPageState extends State<EmailOtpVerifyLoginPage> {
  static const int _otpLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  int _seconds = 115;
  Timer? _timer;
  bool _isLoading = false;

  // FCM Token - Will be fetched from Firebase
  String _fcmToken = "";

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startTimer();
    _initFcmToken();
  }

  // GET FCM TOKEN FROM FIREBASE
  Future<void> _initFcmToken() async {
    try {
      developer.log('Getting FCM token...', name: 'EMAIL_OTP_FCM');

      final fcmService = Provider.of<FirebaseMessagingService>(
        context,
        listen: false,
      );
      final token = await fcmService.getCurrentToken();

      if (token != null && token.isNotEmpty) {
        setState(() {
          _fcmToken = token;
        });
        developer.log(
          'FCM Token Retrieved Successfully!',
          name: 'EMAIL_OTP_FCM',
        );
        developer.log(
          'Token Length: ${token.length} characters',
          name: 'EMAIL_OTP_FCM',
        );
        developer.log(
          'Token Preview: ${token.substring(0, 30)}...',
          name: 'EMAIL_OTP_FCM',
        );
        developer.log('Full Token: $token', name: 'EMAIL_OTP_FCM');
      } else {
        developer.log('FCM token is NULL or EMPTY', name: 'EMAIL_OTP_FCM');
        developer.log('Trying to get token again...', name: 'EMAIL_OTP_FCM');

        // Retry once
        await Future.delayed(const Duration(milliseconds: 500));
        final retryToken = await fcmService.getCurrentToken();

        if (retryToken != null && retryToken.isNotEmpty) {
          setState(() {
            _fcmToken = retryToken;
          });
          developer.log('FCM Token Retrieved on Retry!', name: 'EMAIL_OTP_FCM');
          developer.log('Full Token: $retryToken', name: 'EMAIL_OTP_FCM');
        } else {
          developer.log(
            'Still no FCM token after retry',
            name: 'EMAIL_OTP_FCM',
          );
        }
      }
    } catch (e) {
      developer.log('Error getting FCM token: $e', name: 'EMAIL_OTP_FCM');
      developer.log(
        'Stack trace: ${StackTrace.current}',
        name: 'EMAIL_OTP_FCM',
      );
      developer.log(
        'Continuing without FCM token (non-critical)',
        name: 'EMAIL_OTP_FCM',
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otp.length == _otpLength;

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete) {
      _showToast('Please enter complete OTP', isError: true);
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      developer.log(
        ' Starting Email OTP Verification',
        name: 'EMAIL_OTP_VERIFY',
      );
      developer.log(' Email: ${widget.email}', name: 'EMAIL_OTP_VERIFY');
      developer.log(' OTP: $_otp', name: 'EMAIL_OTP_VERIFY');
      developer.log(
        ' FCM Token being sent: ${_fcmToken.isNotEmpty ? "${_fcmToken.substring(0, 30)}..." : "EMPTY"}',
        name: 'EMAIL_OTP_VERIFY',
      );

      if (_fcmToken.isEmpty) {
        developer.log(
          ' WARNING: Sending EMPTY FCM token!',
          name: 'EMAIL_OTP_VERIFY',
        );
      }
      // Verify Email OTP with FCM token
      final deviceInfo = await LoginDeviceInfoCollector.collect();
      final response = await ApiService().verifyEmailOtpForLogin(
        widget.email,
        _otp,
        fcmToken: _fcmToken,
        deviceInfo: deviceInfo,
      );

      developer.log(
        ' Email OTP Verification Response:',
        name: 'EMAIL_OTP_VERIFY',
      );
      developer.log(
        '   Success: ${response['success']}',
        name: 'EMAIL_OTP_VERIFY',
      );
      developer.log(
        '   Message: ${response['message']}',
        name: 'EMAIL_OTP_VERIFY',
      );

      // Show API message
      final message = response['message'] ?? 'Verification successful';
      _showToast(message, isError: response['success'] != true);

      // On success, save token and navigate
      if (response['success'] == true && mounted) {
        final userProvider = context.read<UserProvider>();

        // Check if token and user data exists in response (direct or in data object)
        final token = response['token'] ?? response['data']?['token'];
        final user = response['user'] ?? response['data']?['user'];

        if (token != null && user != null) {
          developer.log(
            ' User data found - saving...',
            name: 'EMAIL_OTP_VERIFY',
          );

          // Full user data available - save it
          await userProvider.setUserDataFromApi(token: token, user: user);

          developer.log(
            ' User data saved to Provider',
            name: 'EMAIL_OTP_VERIFY',
          );

          // Save FCM token to SharedPreferences
          if (_fcmToken.isNotEmpty) {
            await SharedPrefsHelper.saveFcmToken(_fcmToken);
            developer.log(
              ' FCM token saved to SharedPreferences',
              name: 'EMAIL_OTP_VERIFY',
            );
          } else {
            developer.log(' No FCM token to save', name: 'EMAIL_OTP_VERIFY');
          }

          developer.log(
            ' Email OTP Verification completed successfully!',
            name: 'EMAIL_OTP_VERIFY',
          );

          // Navigate to home
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else if (token != null) {
          developer.log(
            ' Only token found - saving minimal data',
            name: 'EMAIL_OTP_VERIFY',
          );

          // Only token available - save minimal data
          await userProvider.setUserData(
            token: token,
            userId: user?['id'] ?? 0,
            userName: user?['name'] ?? '',
            userEmail: widget.email,
            userPhone: user?['phone'] ?? '',
          );

          // Navigate to EnterFullNamePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EnterFullNamePage()),
          );
        } else {
          developer.log(
            ' No token found in response',
            name: 'EMAIL_OTP_VERIFY',
          );
          _showToast('Login failed. Please try again.', isError: true);
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        ' CRITICAL ERROR in Email OTP Verification',
        name: 'EMAIL_OTP_VERIFY',
      );
      developer.log('   Error: $e', name: 'EMAIL_OTP_VERIFY');
      developer.log('   Stack: $stackTrace', name: 'EMAIL_OTP_VERIFY');

      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    try {
      developer.log(' Resending Email OTP...', name: 'EMAIL_OTP_VERIFY');

      final response = await ApiService().sendEmailOtpForLogin(widget.email);

      final message = response['message'] ?? 'OTP sent successfully';
      _showToast(message, isError: response['success'] != true);

      if (response['success'] == true) {
        developer.log(
          ' Email OTP resent successfully',
          name: 'EMAIL_OTP_VERIFY',
        );
        setState(() => _seconds = 115);
        _startTimer();
      }
    } catch (e) {
      developer.log(' Error resending Email OTP: $e', name: 'EMAIL_OTP_VERIFY');
      _showToast(e.toString(), isError: true);
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
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Title
                const Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    color: Color(0xFF0E0E0E),
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                /// Subtitle
                Text(
                  "We've sent a 6-digit verification code to\nyour email address",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade900),
                ),

                const SizedBox(height: 10),

                /// Email
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 36),

                /// OTP Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _otpLength,
                    (index) => _otpBox(index),
                  ),
                ),

                const SizedBox(height: 46),

                /// Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 3,
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: (_isOtpComplete && !_isLoading)
                        ? _verifyOtp
                        : null,
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
                            'Verify Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 22),

                /// Resend Section
                Text(
                  "Didn't receive the email?",
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 8),

                _seconds == 0
                    ? GestureDetector(
                        onTap: _resendOtp,
                        child: const Text(
                          'Resend Email',
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Text(
                        "Resend available in ${_formatTime(_seconds)}",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),

                const SizedBox(height: 58),

                /// Change Email
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Use a different email address',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// OTP Input Box
  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        enabled: !_isLoading,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.6),
          ),
        ),
        onChanged: (value) {
          if (value.length > 1) {
            _handlePaste(value);
            return;
          }

          if (value.isNotEmpty && index < _otpLength - 1) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }

          setState(() {});
        },
      ),
    );
  }

  void _handlePaste(String value) {
    final chars = value.split('');
    for (int i = 0; i < _otpLength; i++) {
      _controllers[i].text = i < chars.length ? chars[i] : '';
    }
    _focusNodes.last.requestFocus();
    setState(() {});
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
