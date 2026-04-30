// lib/presentation/auth/welcome_page.dart

import 'package:flutter/material.dart';
import 'loginsystem_select_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_back.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          /// Content
          SafeArea(
            child: Center( // THIS FIXES THE SHIFT
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/welcome_page_vector.png',
                    height: 260,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 38,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 14,
                      ),
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const LoginSystemSelectPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Get Started',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
