// lib/presentation/auth/mobile_email_otp_login_verify.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/utils/login_device_info.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'enter_full_name_page.dart';
import 'dart:developer' as developer;

class MobileEmailOtpLoginVerify extends StatefulWidget {
  final String contact;
  final bool isPhone;

  const MobileEmailOtpLoginVerify({
    super.key,
    required this.contact,
    required this.isPhone,
  });

  @override
  State<MobileEmailOtpLoginVerify> createState() =>
      _MobileEmailOtpLoginVerifyState();
}

class _MobileEmailOtpLoginVerifyState extends State<MobileEmailOtpLoginVerify> {
  final int _otpLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  int _seconds = 115;
  Timer? _timer;
  bool _isLoading = false;

  // Generate guest_id once
  final String _guestId = const Uuid().v4();

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
      developer.log('Getting FCM token...', name: 'OTP_VERIFY_FCM');

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
          name: 'OTP_VERIFY_FCM',
        );
        developer.log(
          'Token Length: ${token.length} characters',
          name: 'OTP_VERIFY_FCM',
        );
        developer.log(
          'Token Preview: ${token.substring(0, 30)}...',
          name: 'OTP_VERIFY_FCM',
        );
      } else {
        developer.log('FCM token is NULL or EMPTY', name: 'OTP_VERIFY_FCM');
        developer.log('Trying to get token again...', name: 'OTP_VERIFY_FCM');

        // Retry once
        await Future.delayed(const Duration(milliseconds: 500));
        final retryToken = await fcmService.getCurrentToken();

        if (retryToken != null && retryToken.isNotEmpty) {
          setState(() {
            _fcmToken = retryToken;
          });
          developer.log(
            'FCM Token Retrieved on Retry!',
            name: 'OTP_VERIFY_FCM',
          );
        } else {
          developer.log(
            'Still no FCM token after retry',
            name: 'OTP_VERIFY_FCM',
          );
        }
      }
    } catch (e) {
      developer.log('Error getting FCM token: $e', name: 'OTP_VERIFY_FCM');
      developer.log(
        'Continuing without FCM token (non-critical)',
        name: 'OTP_VERIFY_FCM',
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

    // Prevent multiple clicks
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      developer.log(
        '═══════════════════════════════════════',
        name: 'OTP_VERIFY',
      );
      developer.log('Starting OTP Verification', name: 'OTP_VERIFY');
      developer.log('Contact: ${widget.contact}', name: 'OTP_VERIFY');
      developer.log('Is Phone: ${widget.isPhone}', name: 'OTP_VERIFY');
      developer.log('OTP: $_otp', name: 'OTP_VERIFY');
      developer.log(
        'FCM Token: ${_fcmToken.isNotEmpty ? "${_fcmToken.substring(0, 30)}..." : "EMPTY"}',
        name: 'OTP_VERIFY',
      );
      developer.log('Guest ID: $_guestId', name: 'OTP_VERIFY');
      developer.log(
        '═══════════════════════════════════════',
        name: 'OTP_VERIFY',
      );

      Map<String, dynamic> response;
      final deviceInfo = await LoginDeviceInfoCollector.collect();

      if (widget.isPhone) {
        // Verify Phone OTP
        response = await ApiService().verifyPhoneOtp({
          'mobile': widget.contact,
          'otp': _otp,
          'fcm_token': _fcmToken,
          'guest_id': _guestId,
          ...deviceInfo.toJson(),
        });
      } else {
        // Verify Email OTP
        response = await ApiService().verifyEmailOtp({
          'email': widget.contact,
          'otp': _otp,
          'fcm_token': _fcmToken,
          'guest_id': _guestId,
          ...deviceInfo.toJson(),
        });
      }

      developer.log('OTP Verification Response:', name: 'OTP_VERIFY');
      developer.log('Success: ${response['success']}', name: 'OTP_VERIFY');
      developer.log('Message: ${response['message']}', name: 'OTP_VERIFY');

      // Show API message
      final message =
          response['message'] ??
          (response['success'] == true
              ? 'OTP verified successfully'
              : 'Invalid OTP');

      _showToast(message, isError: response['success'] != true);

      // Handle success
      if (response['success'] == true) {
        // Check if user data exists (existing user)
        if (response['user'] != null && response['token'] != null) {
          developer.log('Existing user found - logging in', name: 'OTP_VERIFY');

          // Existing user - save login data and navigate to home
          final userProvider = context.read<UserProvider>();
          await userProvider.setUserDataFromApi(
            token: response['token'],
            user: response['user'],
          );

          developer.log('User data saved to Provider', name: 'OTP_VERIFY');

          // Save FCM token to SharedPreferences
          if (_fcmToken.isNotEmpty) {
            await SharedPrefsHelper.saveFcmToken(_fcmToken);
            developer.log(
              'FCM token saved to SharedPreferences',
              name: 'OTP_VERIFY',
            );
          }

          developer.log(
            'OTP Verification completed successfully!',
            name: 'OTP_VERIFY',
          );

          if (mounted) {
            // Navigate to home/dashboard
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        } else {
          developer.log(
            'New user - navigating to registration',
            name: 'OTP_VERIFY',
          );

          // New user - navigate to registration page
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EnterFullNamePage()),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '═══════════════════════════════════════',
        name: 'OTP_VERIFY',
      );
      developer.log('CRITICAL ERROR in OTP Verification', name: 'OTP_VERIFY');
      developer.log('Error: $e', name: 'OTP_VERIFY');
      developer.log('Stack: $stackTrace', name: 'OTP_VERIFY');
      developer.log(
        '═══════════════════════════════════════',
        name: 'OTP_VERIFY',
      );

      _showToast('Error: ${e.toString()}', isError: true);
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
      developer.log('Resending OTP...', name: 'OTP_VERIFY');

      Map<String, dynamic> response;

      if (widget.isPhone) {
        response = await ApiService().sendPhoneOtp({'mobile': widget.contact});
      } else {
        response = await ApiService().sendEmailOtp({'email': widget.contact});
      }

      final message =
          response['message'] ??
          (response['success'] == true
              ? 'OTP resent successfully'
              : 'Failed to resend OTP');

      _showToast(message, isError: response['success'] != true);

      if (response['success'] == true) {
        developer.log('OTP resent successfully', name: 'OTP_VERIFY');
        setState(() => _seconds = 115);
        _startTimer();
      }
    } catch (e) {
      developer.log('Error resending OTP: $e', name: 'OTP_VERIFY');
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
                  "We've sent a 6-digit verification code to your\n${widget.isPhone ? 'phone' : 'email'}",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 10),

                // Contact
                Text(
                  widget.contact,
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
                            'Verify Code',
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
