import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/status_badge_widget.dart';

class OwnerRecentBookingsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final ValueChanged<String> onConfirm;
  final ValueChanged<String> onComplete;

  const OwnerRecentBookingsWidget({
    super.key,
    required this.bookings,
    required this.onConfirm,
    required this.onComplete,
  });

  BookingStatus _parseStatus(String s) {
    switch (s) {
      case 'CONFIRMED':
        return BookingStatus.confirmed;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'COMPLETED':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }

  String _formatVnd(int amount) {
    final s = amount.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Booking gần đây',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${bookings.where((b) => b['status'] == 'PENDING').length} chờ xử lý',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bookings.map((booking) {
            final status = _parseStatus(booking['status'] as String);
            final isPending = booking['status'] == 'PENDING';
            final isConfirmed = booking['status'] == 'CONFIRMED';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isPending
                    ? Border.all(
                        color: AppTheme.warning.withAlpha(102),
                        width: 1.5,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isPending
                            ? AppTheme.secondaryContainer
                            : AppTheme.primaryContainer,
                        child: Text(
                          booking['avatarLetter'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isPending
                                ? AppTheme.warning
                                : AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking['customerName'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${booking['courtLabel']} · ${booking['startTime']} – ${booking['endTime']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_formatVnd(booking['price'] as int)} VND',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          StatusBadgeWidget.booking(status),
                        ],
                      ),
                    ],
                  ),
                  if (isPending || isConfirmed) ...[
                    const SizedBox(height: 10),
                    Container(height: 1, color: AppTheme.outline.withAlpha(51)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isPending)
                          _ActionButton(
                            label: 'Xác nhận',
                            icon: Icons.check_rounded,
                            color: AppTheme.success,
                            bgColor: AppTheme.primaryContainer,
                            onPressed: () => onConfirm(booking['id'] as String),
                          ),
                        if (isConfirmed)
                          _ActionButton(
                            label: 'Hoàn tất',
                            icon: Icons.task_alt_rounded,
                            color: AppTheme.info,
                            bgColor: const Color(0xFFE3F2FD),
                            onPressed: () =>
                                onComplete(booking['id'] as String),
                          ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          label: 'Chi tiết',
                          icon: Icons.info_outline_rounded,
                          color: AppTheme.muted,
                          bgColor: AppTheme.background,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
