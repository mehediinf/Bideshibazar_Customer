// lib/presentation/splash/splash_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'splash_viewmodel.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _logoScale;
  late Animation<double> _fadeTitle;
  late Animation<double> _fadeTagline;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
    );

    _fadeTitle = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );

    _fadeTagline = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    Future.microtask(() {
      Provider.of<SplashViewModel>(context, listen: false)
          .initialize(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            ScaleTransition(
              scale: _logoScale,
              child: Image.asset(
                "assets/images/app_logo.jpg",
                width: 120,
                height: 120,
              ),
            ),

            const SizedBox(height: 20),

            FadeTransition(
              opacity: _fadeTitle,
              child: const Text(
                "BideshiBazar",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 10),

            FadeTransition(
              opacity: _fadeTagline,
              child: const Text(
                "Shop Confidently with BideshiBazar",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 40),

            /// Wave Spinner Added
            const SpinKitWaveSpinner(
              color: Colors.blue,
              size: 55,
            ),
          ],
        ),
      ),
    );
  }
}
