import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class DemoCredentialsWidget extends StatelessWidget {
  final String demoEmail;
  final String demoPassword;
  final String ownerEmail;
  final String ownerPassword;

  const DemoCredentialsWidget({
    super.key,
    required this.demoEmail,
    required this.demoPassword,
    required this.ownerEmail,
    required this.ownerPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Tài khoản demo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCredRow(context, '👤 Khách hàng', demoEmail, demoPassword),
          const SizedBox(height: 4),
          _buildCredRow(context, '🏢 Chủ sân', ownerEmail, ownerPassword),
        ],
      ),
    );
  }

  Widget _buildCredRow(
    BuildContext context,
    String role,
    String email,
    String pass,
  ) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: '$email / $pass'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã sao chép thông tin $role'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(179),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(
              role,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const Text(' · ', style: TextStyle(color: AppTheme.muted)),
            Expanded(
              child: Text(
                '$email · $pass',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.muted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.copy_outlined, size: 12, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}
