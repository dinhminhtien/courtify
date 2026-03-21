import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class CancellationPolicyWidget extends StatelessWidget {
  const CancellationPolicyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.warning,
              ),
              const SizedBox(width: 8),
              Text(
                'Chính sách hủy đặt sân',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PolicyItem(
            icon: Icons.check_circle_outline_rounded,
            text: 'Hủy trước 2 giờ: Hoàn tiền 100%',
            color: AppTheme.success,
          ),
          const SizedBox(height: 6),
          _PolicyItem(
            icon: Icons.remove_circle_outline_rounded,
            text: 'Hủy trong vòng 2 giờ: Hoàn tiền 50%',
            color: AppTheme.warning,
          ),
          const SizedBox(height: 6),
          _PolicyItem(
            icon: Icons.cancel_outlined,
            text: 'Không hủy sau khi đã bắt đầu giờ chơi',
            color: AppTheme.error,
          ),
        ],
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _PolicyItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
