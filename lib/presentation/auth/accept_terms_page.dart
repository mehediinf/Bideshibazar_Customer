// lib/presentation/auth/accept_terms_page.dart

import 'package:flutter/material.dart';
import '../main_screen.dart';
import 'enter_full_name_page.dart';

class AcceptTermsPage extends StatefulWidget {
  const AcceptTermsPage({super.key});

  @override
  State<AcceptTermsPage> createState() => _AcceptTermsPageState();
}

class _AcceptTermsPageState extends State<AcceptTermsPage> {
  bool isChecked = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            // Top Back Button
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    // Navigate back to EnterFullNamePage
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EnterFullNamePage(),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // Center Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      const Text(
                        "Accept BideshiBazar's\nTerms\nand Review Privacy Policy",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        "By selecting 'I Agree', you confirm that you have reviewed and accepted the following terms:",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Column(
                        children: const [
                          Text(
                            "• Terms of Use",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• Privacy Policy",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• I am at least 16 years old.",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            //  Bottom Actions
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [

                  Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        activeColor: Colors.orange,
                        onChanged: (v) {
                          setState(() => isChecked = v ?? false);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "I Agree to the above Terms",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isChecked
                          ? () {
                        // Remove all previous routes and go to MainScreen
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainScreen(),
                          ),
                              (route) => false,
                        );
                      }
                          : null,
                      child: const Text(
                        "SUBMIT  →",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}