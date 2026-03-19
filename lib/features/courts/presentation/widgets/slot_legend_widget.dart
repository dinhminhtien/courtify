import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class SlotLegendWidget extends StatelessWidget {
  const SlotLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Chú thích: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.muted,
          ),
        ),

          _LegendItem(
            color: AppTheme.slotAvailable,
            textColor: AppTheme.slotAvailableText,
            label: 'Trống',
          ),
          const SizedBox(width: 8),
          _LegendItem(
            color: AppTheme.slotHold,
            textColor: AppTheme.slotHoldText,
            label: 'Đang giữ',
          ),
          const SizedBox(width: 8),
          _LegendItem(
            color: AppTheme.slotBooked,
            textColor: AppTheme.slotBookedText,
            label: 'Đã đặt',
          ),
          const SizedBox(width: 8),
          _LegendItem(
            color: AppTheme.slotBlocked,
            textColor: AppTheme.slotBlockedText,
            label: 'Khóa',
          ),
        ],
      );

  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String label;

  const _LegendItem({
    required this.color,
    required this.textColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),

      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
