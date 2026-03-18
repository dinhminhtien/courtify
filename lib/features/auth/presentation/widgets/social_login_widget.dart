import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialLoginWidget extends StatelessWidget {
  final VoidCallback onGooglePressed;
  const SocialLoginWidget({super.key, required this.onGooglePressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onGooglePressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF374151),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Icon(
                Icons.g_mobiledata_rounded,
                size: 24,
                color: Color(0xFFDB4437),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Đăng nhập bằng Google',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
