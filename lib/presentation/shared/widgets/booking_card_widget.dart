import 'package:flutter/material.dart';
import 'package:courtify/core/theme/app_theme.dart';
import 'package:courtify/domain/entities/booking.dart';
import 'package:courtify/l10n/app_localizations.dart';

class BookingCardWidget extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancelTap;
  final VoidCallback? onPayTap;

  const BookingCardWidget({
    super.key,
    required this.booking,
    this.onCancelTap,
    this.onPayTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final firstSlot = booking.slots.isNotEmpty ? booking.slots.first : null;
    final courtName = firstSlot?.court?.name ?? 'Sân';
    final bookDate = firstSlot?.date ?? DateTime.now();
    final timeRange = firstSlot != null ? '${firstSlot.startTime} - ${firstSlot.endTime}' : '--:--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.court}: $courtName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                _buildStatusBadge(context, booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${bookDate.year}-${bookDate.month.toString().padLeft(2, '0')}-${bookDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  timeRange,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.totalPrice, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(
                      '\$${booking.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ],
                ),
                _buildActionButtons(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, BookingStatus status) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pending:
        color = AppColors.warning;
        text = l10n.pending;
        break;
      case BookingStatus.confirmed:
        color = AppColors.primaryLight;
        text = l10n.confirmed;
        break;
      case BookingStatus.completed:
        color = AppColors.success;
        text = l10n.completed;
        break;
      case BookingStatus.cancelled:
        color = AppColors.error;
        text = l10n.cancelled;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    // Use domain logic (BR-C10)
    final canCancel = booking.canCancel(now);

    return Row(
      children: [
        if (booking.paymentStatus == PaymentStatus.unpaid &&
            booking.status != BookingStatus.cancelled &&
            booking.status != BookingStatus.completed)
          TextButton(
            onPressed: onPayTap,
            child: Text(l10n.payNow, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          ),
        if (canCancel)
          TextButton(
            onPressed: onCancelTap,
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
