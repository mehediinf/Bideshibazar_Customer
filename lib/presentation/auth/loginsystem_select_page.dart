// lib/presentation/auth/loginsystem_select_page.dart

import 'package:flutter/material.dart';
import 'package:bideshibazar/presentation/auth/login_page.dart';
import 'package:bideshibazar/presentation/auth/mobile_email_otp_login.dart';
import 'package:bideshibazar/presentation/main_screen.dart';


class LoginSystemSelectPage extends StatelessWidget {
  const LoginSystemSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF3C0),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center( // main center
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // important for centering
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // Logo
                    Container(
                      padding: const EdgeInsets.all(14),
                      // decoration: BoxDecoration(
                      //   color: Colors.white,
                      //   shape: BoxShape.circle,
                      //   boxShadow: [
                      //     BoxShadow(
                      //       color: Colors.black.withOpacity(0.08),
                      //       blurRadius: 12,
                      //       offset: const Offset(0, 4),
                      //     )
                      //   ],
                      // ),
                      child: Image.asset(
                        'assets/images/app_font_page.png',
                        height: 100,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Welcome to Bideshi Bazar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Sign in or create an account to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 36),

                    // Card Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          // Already a customer
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Already a customer? Sign in',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),


                          const SizedBox(height: 16),

                          // Create account
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              side: const BorderSide(color: Colors.black12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MobileEmailOtpLogin(),
                                ),
                              );
                            },
                            child: const Text(
                              'New to Bideshibazar? Create an account',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Skip sign in
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Skip sign in',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
