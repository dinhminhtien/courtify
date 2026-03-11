import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courtify/core/theme/app_theme.dart';
import 'package:courtify/domain/entities/booking.dart';
import 'package:courtify/presentation/shared/widgets/booking_card_widget.dart';

import 'package:courtify/l10n/app_localizations.dart';

import 'package:courtify/presentation/features/booking/providers/booking_provider.dart';
import 'package:courtify/presentation/features/court/screens/visual_booking_screen.dart';

class CustomerBookingsScreen extends ConsumerWidget {
  const CustomerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch real data
    final bookingsAsync = ref.watch(customerBookingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.mySchedule, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: bookingsAsync.when(
        data: (bookings) => bookings.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return BookingCardWidget(
                    booking: booking,
                    onCancelTap: () {
                      _showCancelDialog(context, ref, booking);
                    },
                    onPayTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.redirectingToPayment)),
                      );
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VisualBookingScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            l10n.noBookingsYet,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bookCourtToStart,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.cancelBookingDialogTitle),
          content: Text(l10n.cancelBookingDialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.keepIt, style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final notifier = ref.read(bookingActionProvider.notifier);
                await notifier.cancelBooking(booking.id);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.bookingCancelledSuccessfully)),
                  );
                }
              },
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
