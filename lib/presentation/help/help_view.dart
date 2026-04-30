//lib/presentation/help/help_view.dart

import 'package:flutter/material.dart';
import 'faq_tab.dart';
import 'our_story_tab.dart';
import 'team_tab.dart';
import 'career_tab.dart';
import 'contact_us_tab.dart';
import 'privacy_policy_tab.dart';
import 'terms_of_use_tab.dart';

class HelpView extends StatefulWidget {
  final int initialTabIndex;

  const HelpView({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Header images for each tab
  final List<String> _headerImages = [
    'assets/images/faq_image.webp',
    'assets/images/our_story_image.jpg',
    'assets/images/team_image.jpg',
    'assets/images/career_image.jpg',
    'assets/images/contact_us_image.jpg',
    'assets/images/privacy_policy_image.jpg',
    'assets/images/terms_of_use_image.png',
  ];

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex.clamp(0, 6);
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: _currentTabIndex,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom AppBar with Back button
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.only(left: 16),
              color: Colors.white,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Header Image with Wave Overlay
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    _headerImages[_currentTabIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Wave Overlay at Bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: const Size(double.infinity, 40),
                    painter: WavePainter(),
                  ),
                ),
              ],
            ),
          ),

          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF0071CE),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF0071CE),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: const [
                Tab(text: 'FAQ'),
                Tab(text: 'Our Story'),
                Tab(text: 'Team'),
                Tab(text: 'Career'),
                Tab(text: 'Contact Us'),
                Tab(text: 'Privacy Policy'),
                Tab(text: 'Terms of Use'),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FaqTab(),
                OurStoryTab(),
                TeamTab(),
                CareerTab(),
                ContactUsTab(),
                PrivacyPolicyTab(),
                TermsOfUseTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Wave Painter
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    // Starting point
    path.moveTo(0, 0);

    // Create wave curve
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.4,
      size.width * 0.42,
      size.height * 0.8,
      size.width,
      0,
    );

    // Complete the path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
