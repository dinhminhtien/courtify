import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/status_badge_widget.dart';

class BookingHistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback? onCancel;
  final VoidCallback? onPayNow;

  const BookingHistoryCardWidget({
    super.key,
    required this.booking,
    this.onCancel,
    this.onPayNow,
  });

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
    final status = booking['status'] as String;
    final paymentStatus = booking['paymentStatus'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sports_tennis_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sân ${booking['courtNumber']}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              StatusBadgeWidget.booking(_parseStatus(status)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sân cầu lông Courtify',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: AppTheme.outline.withAlpha(51)),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: booking['dateFormatted']?.toString() ?? 'N/A',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: '${booking['startTime']} – ${booking['endTime']}',
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoRow(
                      icon: Icons.payments_outlined,
                      label: '${_formatVnd(booking['price'] as int)} VND',
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    StatusBadgeWidget.payment(_parsePaymentStatus(paymentStatus)),
                  ],
                ),
              ],
            ),
          ),
          if (onCancel != null || onPayNow != null) ...[
            Container(height: 1, color: AppTheme.outline.withAlpha(51)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (onCancel != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Hủy đặt sân'),
                      ),
                    ),
                  if (onCancel != null && onPayNow != null)
                    const SizedBox(width: 12),
                  if (onPayNow != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onPayNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Thanh toán ngay'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

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

  PaymentStatus _parsePaymentStatus(String s) {
    switch (s) {
      case 'PAID':
        return PaymentStatus.paid;
      default:
        return PaymentStatus.unpaid;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle? labelStyle;

  const _InfoRow({required this.icon, required this.label, this.labelStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.muted),
        const SizedBox(width: 8),
        Text(
          label,
          style: labelStyle ??
              GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF374151),
              ),
        ),
      ],
    );
  }
}
