import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark Gradient Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(0),
                    Colors.black.withAlpha(40),
                    Colors.black.withAlpha(180),
                  ],
                  stops: const [0.0, 0.4, 0.9],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    'CHƠI CẦU LÔNG\nTHEO CÁCH RIÊNG',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tìm sân, đặt lịch và tận hưởng niềm vui\ncầu lông mọi lúc, mọi nơi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: Colors.white.withAlpha(200),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_tennis_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, AppRoutes.signUpLogin);
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Bắt đầu ngay',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
