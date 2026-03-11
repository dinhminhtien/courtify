import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courtify/core/theme/app_theme.dart';
import 'package:courtify/domain/entities/booking.dart';
import 'package:intl/intl.dart';

import 'package:courtify/l10n/app_localizations.dart';

import 'package:courtify/presentation/features/booking/providers/booking_provider.dart';

class OwnerBookingManagementScreen extends ConsumerWidget {
  const OwnerBookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BR-O3: Owner sees all bookings (Real Data)
    final bookingsAsync = ref.watch(ownerBookingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.manageBookings, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: bookingsAsync.when(
        data: (bookings) => bookings.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _buildOwnerBookingCard(context, ref, booking);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n.noBookingsFound,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerBookingCard(BuildContext context, WidgetRef ref, Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    
    final firstSlot = booking.slots.isNotEmpty ? booking.slots.first : null;
    final courtName = firstSlot?.court?.name ?? 'Sân';
    final bookDate = firstSlot?.date ?? DateTime.now();
    final timeRange = firstSlot != null ? '${firstSlot.startTime} - ${firstSlot.endTime}' : '--:--';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$courtName • ${booking.userName ?? 'User #${booking.userId}'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(context, booking.status),
              ],
            ),
            const SizedBox(height: 12),
            
            // Details Row
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(bookDate),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(width: 16),
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

            // Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n.total} / ${l10n.payment}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Row(
                      children: [
                        Text(
                          '\$${booking.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                        const SizedBox(width: 8),
                        _buildPaymentBadge(context, booking.paymentStatus),
                      ],
                    ),
                  ],
                ),
                _buildOwnerActionButtons(context, ref, booking),
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
      case BookingStatus.pending: color = AppColors.warning; text = l10n.pending; break;
      case BookingStatus.confirmed: color = AppColors.primaryLight; text = l10n.confirmed; break;
      case BookingStatus.completed: color = AppColors.success; text = l10n.completed; break;
      case BookingStatus.cancelled: color = AppColors.error; text = l10n.cancelled; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildPaymentBadge(BuildContext context, PaymentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    final isPaid = status == PaymentStatus.paid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPaid ? AppColors.success : AppColors.error,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPaid ? l10n.paid : l10n.unpaid,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // BR-O4: Owner can change status: PENDING -> CONFIRMED -> COMPLETED, or CANCELLED
  Widget _buildOwnerActionButtons(BuildContext context, WidgetRef ref, Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.primary),
      onSelected: (action) => _handleOwnerAction(context, ref, action, l10n, booking),
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> items = [];

        // Dynamic rules engine for Owner actions
        if (booking.status == BookingStatus.pending) {
          items.add(PopupMenuItem(value: 'confirm', child: Text(l10n.markConfirmed)));
          items.add(PopupMenuItem(value: 'cancel', child: Text(l10n.cancelBooking, style: const TextStyle(color: Colors.red))));
        } else if (booking.status == BookingStatus.confirmed) {
          // BR-O6 checks can be enforced here or in validation logic
          items.add(PopupMenuItem(value: 'complete', child: Text(l10n.markCompleted, style: const TextStyle(color: Colors.green))));
          items.add(PopupMenuItem(value: 'cancel', child: Text(l10n.cancelBooking, style: const TextStyle(color: Colors.red))));
        }

        if (items.isEmpty) {
          items.add(PopupMenuItem(value: 'none', enabled: false, child: Text(l10n.noActionsAvailable)));
        }
        return items;
      },
    );
  }

  void _handleOwnerAction(BuildContext context, WidgetRef ref, String action, AppLocalizations l10n, Booking booking) async {
    final now = DateTime.now();
    BookingStatus newStatus;

    if (action == 'confirm') {
      newStatus = BookingStatus.confirmed;
    } else if (action == 'complete') {
      // Logic constraint: BR-O6
      if (booking.canBeMarkedCompleted(now, true)) { // Assuming they manually checked-in
        newStatus = BookingStatus.completed;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cannotCompleteError)),
        );
        return;
      }
    } else if (action == 'cancel') {
      newStatus = BookingStatus.cancelled;
    } else {
      return;
    }

    final notifier = ref.read(bookingActionProvider.notifier);
    await notifier.updateStatus(booking.id, newStatus);

    if (context.mounted) {
      String statusText;
      switch (newStatus) {
        case BookingStatus.pending: statusText = l10n.pending; break;
        case BookingStatus.confirmed: statusText = l10n.confirmed; break;
        case BookingStatus.completed: statusText = l10n.completed; break;
        case BookingStatus.cancelled: statusText = l10n.cancelled; break;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.bookingUpdated}: $statusText')));
    }
  }
}
