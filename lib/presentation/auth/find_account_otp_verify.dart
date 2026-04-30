// lib/presentation/auth/find_account_otp_verify.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/utils/login_device_info.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../main_screen.dart';
import 'dart:developer' as developer;

class FindAccountOtpVerify extends StatefulWidget {
  final String identifier;
  final String userName;

  const FindAccountOtpVerify({
    super.key,
    required this.identifier,
    required this.userName,
  });

  @override
  State<FindAccountOtpVerify> createState() => _FindAccountOtpVerifyState();
}

class _FindAccountOtpVerifyState extends State<FindAccountOtpVerify> {
  final int _otpLength = 6;
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
      developer.log('Getting FCM token...', name: 'FIND_ACCOUNT_OTP_FCM');

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
          name: 'FIND_ACCOUNT_OTP_FCM',
        );
        developer.log(
          'Token Length: ${token.length} characters',
          name: 'FIND_ACCOUNT_OTP_FCM',
        );
        developer.log(
          'Token Preview: ${token.substring(0, 30)}...',
          name: 'FIND_ACCOUNT_OTP_FCM',
        );
      } else {
        developer.log(
          'FCM token is NULL or EMPTY',
          name: 'FIND_ACCOUNT_OTP_FCM',
        );
        developer.log(
          'Trying to get token again...',
          name: 'FIND_ACCOUNT_OTP_FCM',
        );

        // Retry once
        await Future.delayed(const Duration(milliseconds: 500));
        final retryToken = await fcmService.getCurrentToken();

        if (retryToken != null && retryToken.isNotEmpty) {
          setState(() {
            _fcmToken = retryToken;
          });
          developer.log(
            'FCM Token Retrieved on Retry!',
            name: 'FIND_ACCOUNT_OTP_FCM',
          );
        } else {
          developer.log(
            'Still no FCM token after retry',
            name: 'FIND_ACCOUNT_OTP_FCM',
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error getting FCM token: $e',
        name: 'FIND_ACCOUNT_OTP_FCM',
      );
      developer.log(
        'Continuing without FCM token (non-critical)',
        name: 'FIND_ACCOUNT_OTP_FCM',
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

  Future<void> _verifyOtp() async {
    if (_otp.length != _otpLength) {
      _showToast('Please enter complete OTP', isError: true);
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final deviceInfo = await LoginDeviceInfoCollector.collect();
      final response = await ApiService().verifyLoginOtp(
        widget.identifier,
        _otp,
        fcmToken: _fcmToken.isNotEmpty ? _fcmToken : null,
        deviceInfo: deviceInfo,
      );

      developer.log('OTP Verification Response:', name: 'FIND_ACCOUNT_OTP');
      developer.log(
        'Success: ${response['success']}',
        name: 'FIND_ACCOUNT_OTP',
      );
      developer.log(
        'Message: ${response['message']}',
        name: 'FIND_ACCOUNT_OTP',
      );

      // Show API message
      final message = response['message'] ?? 'Login successful';
      _showToast(message, isError: response['success'] != true);

      // Handle success - save token and navigate to home
      if (response['success'] == true && mounted) {
        // Check if token and user data exists
        final token = response['token'];
        final user = response['user'];

        if (token != null && user != null) {
          developer.log(
            'User data found - logging in',
            name: 'FIND_ACCOUNT_OTP',
          );

          final userProvider = context.read<UserProvider>();
          await userProvider.setUserDataFromApi(token: token, user: user);

          developer.log(
            'User data saved to Provider',
            name: 'FIND_ACCOUNT_OTP',
          );

          // Save FCM token to SharedPreferences
          if (_fcmToken.isNotEmpty) {
            await SharedPrefsHelper.saveFcmToken(_fcmToken);
            developer.log(
              'FCM token saved to SharedPreferences',
              name: 'FIND_ACCOUNT_OTP',
            );
          }

          developer.log(
            'Login completed successfully!',
            name: 'FIND_ACCOUNT_OTP',
          );

          if (mounted) {
            // Navigate to MainScreen and clear all previous routes
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      developer.log('Resending OTP...', name: 'FIND_ACCOUNT_OTP');

      final response = await ApiService().sendLoginOtp(widget.identifier);

      final message = response['message'] ?? 'OTP sent successfully';
      _showToast(message, isError: response['success'] != true);

      if (response['success'] == true) {
        developer.log('OTP resent successfully', name: 'FIND_ACCOUNT_OTP');
        setState(() => _seconds = 115);
        _startTimer();
      }
    } catch (e) {
      developer.log('Error resending OTP: $e', name: 'FIND_ACCOUNT_OTP');
      _showToast(e.toString(), isError: true);
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
    // Determine if it's email or phone
    final isEmail = widget.identifier.contains('@');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                const Text(
                  'Almost there!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 14),

                // Subtitle
                Text(
                  "We've sent a 6-digit verification code to your\n${isEmail ? 'email' : 'phone'}",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 10),

                // Identifier (email/phone)
                Text(
                  widget.identifier,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 36),

                // OTP Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _otpLength,
                    (index) => _otpBox(index),
                  ),
                ),

                const SizedBox(height: 46),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: (_otp.length == _otpLength && !_isLoading)
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
                            'Verify & Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 22),

                // Resend Section
                Text(
                  "Didn't receive the code?",
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 8),

                _seconds == 0
                    ? GestureDetector(
                        onTap: _isLoading ? null : _resendOtp,
                        child: Text(
                          'Resend',
                          style: TextStyle(
                            color: _isLoading ? Colors.grey : Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Text(
                        "Request a new code in ${_formatTime(_seconds)}",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),

                const SizedBox(height: 58),

                // Change Contact
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Use a different email or mobile number',
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

  // OTP Input Box (Paste supported)
  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      height: 48,
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
