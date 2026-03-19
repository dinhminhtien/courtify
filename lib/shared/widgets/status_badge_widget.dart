import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum BookingStatus { pending, confirmed, cancelled, completed }

enum PaymentStatus { unpaid, paid }

enum SlotStatus { available, hold, booked, blocked }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadgeWidget.booking(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return StatusBadgeWidget(
          label: 'Chờ xác nhận',
          backgroundColor: AppTheme.warning.withValues(alpha: 0.12),
          textColor: AppTheme.warning,
          icon: Icons.hourglass_empty_rounded,
        );
      case BookingStatus.confirmed:
        return StatusBadgeWidget(
          label: 'Đã xác nhận',
          backgroundColor: AppTheme.success.withValues(alpha: 0.12),
          textColor: AppTheme.success,
          icon: Icons.check_circle_outline_rounded,
        );
      case BookingStatus.cancelled:
        return StatusBadgeWidget(
          label: 'Đã hủy',
          backgroundColor: AppTheme.error.withValues(alpha: 0.12),
          textColor: AppTheme.error,
          icon: Icons.cancel_outlined,
        );
      case BookingStatus.completed:
        return StatusBadgeWidget(
          label: 'Hoàn tất',
          backgroundColor: AppTheme.info.withValues(alpha: 0.12),
          textColor: AppTheme.info,
          icon: Icons.task_alt_rounded,
        );
    }

  }

  factory StatusBadgeWidget.payment(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return StatusBadgeWidget(
          label: 'Chưa thanh toán',
          backgroundColor: AppTheme.warning.withValues(alpha: 0.12),
          textColor: AppTheme.warning,
          icon: Icons.payment_outlined,
        );
      case PaymentStatus.paid:
        return StatusBadgeWidget(
          label: 'Đã thanh toán',
          backgroundColor: AppTheme.success.withValues(alpha: 0.12),
          textColor: AppTheme.success,
          icon: Icons.check_rounded,
        );
    }

  }

  factory StatusBadgeWidget.slot(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return const StatusBadgeWidget(
          label: 'Trống',
          backgroundColor: AppTheme.slotAvailable,
          textColor: AppTheme.slotAvailableText,
        );
      case SlotStatus.hold:
        return const StatusBadgeWidget(
          label: 'Đang giữ',
          backgroundColor: AppTheme.slotHold,
          textColor: AppTheme.slotHoldText,
        );
      case SlotStatus.booked:
        return const StatusBadgeWidget(
          label: 'Đã đặt',
          backgroundColor: AppTheme.slotBooked,
          textColor: AppTheme.slotBookedText,
        );
      case SlotStatus.blocked:
        return const StatusBadgeWidget(
          label: 'Khóa',
          backgroundColor: AppTheme.slotBlocked,
          textColor: AppTheme.slotBlockedText,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
