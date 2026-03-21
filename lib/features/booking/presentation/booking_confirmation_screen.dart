import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import './providers/bookings_provider.dart';
import '../../payment/presentation/providers/payment_provider.dart';
import './widgets/booking_summary_card_widget.dart';
import './widgets/cancellation_policy_widget.dart';
import './widgets/hold_timer_widget.dart';
import './widgets/price_breakdown_widget.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? bookingArgs;

  const BookingConfirmationScreen({super.key, this.bookingArgs});

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  bool _holdStarted = false;
  String _selectedPaymentMethod = 'online'; // 'online' | 'cash'

  late List<Map<String, dynamic>> _slots;
  late Map<String, dynamic> _slot; // first slot (for compat)
  late Map<String, dynamic> _court;

  @override
  void initState() {
    super.initState();
    final args = widget.bookingArgs;

    // Support both single slot and multiple slots
    final slotsArg = args?['slots'] as List<dynamic>?;
    if (slotsArg != null && slotsArg.isNotEmpty) {
      _slots = slotsArg.cast<Map<String, dynamic>>();
    } else {
      final singleSlot =
          args?['slot'] as Map<String, dynamic>? ??
          {
            'id': 'slot-demo-1',
            'startTime': '08:00',
            'endTime': '09:00',
            'price': 60000,
            'status': 'AVAILABLE',
            'courtNumber': 2,
            'date': DateTime.now(),
          };
      _slots = [singleSlot];
    }
    _slot = _slots.first;
    _court =
        args?['court'] as Map<String, dynamic>? ??
        {'id': 'court-2', 'number': 2, 'label': 'Sân 2'};
  }

  int get _totalPrice => _slots.fold(0, (sum, s) => sum + (s['price'] as int));

  Future<void> _createBookingAndPay() async {
    // Validate: ensure no slot is in the past
    for (final slot in _slots) {
      final date = slot['date'];
      if (date != null) {
        final slotDate = date is DateTime
            ? date
            : DateTime.tryParse(date.toString());
        if (slotDate != null) {
          final startTimeParts = (slot['startTime'] as String).split(':');
          final hour = int.tryParse(startTimeParts[0]) ?? 0;
          final minute = startTimeParts.length > 1
              ? (int.tryParse(startTimeParts[1]) ?? 0)
              : 0;
          final slotDateTime = DateTime(
            slotDate.year,
            slotDate.month,
            slotDate.day,
            hour,
            minute,
          );
          if (slotDateTime.isBefore(DateTime.now())) {
            _showError('Không thể đặt slot đã qua. Vui lòng chọn slot khác.');
            return;
          }
        }
      }
    }

    try {
      final slotIds = _slots.map((s) => s['id'] as String).toList();
      ref.read(paymentProvider.notifier).reset(); // Reset payment state
      final booking = await ref
          .read(bookingsProvider.notifier)
          .createBooking(slotIds: slotIds, courtId: _court['id'] as String);

      if (!mounted) return;

      if (booking != null) {
        if (_selectedPaymentMethod == 'cash') {
          await ref
              .read(paymentProvider.notifier)
              .confirmCashPayment(bookingId: booking.id, slotIds: slotIds);

          if (!mounted) return;
          Navigator.pushNamed(
            context,
            AppRoutes.payment,
            arguments: {
              'slots': _slots,
              'slot': _slot,
              'court': _court,
              'bookingId': booking.id,
              'totalAmount': _totalPrice,
              'paymentMethod': 'cash',
            },
          );
        } else {
          setState(() => _holdStarted = true);
          final bookingsState = ref.read(bookingsProvider);
          Navigator.pushNamed(
            context,
            AppRoutes.payment,
            arguments: {
              'slots': _slots,
              'slot': _slot,
              'court': _court,
              'holdExpiresAt': bookingsState.holdExpiresAt,
              'bookingId': booking.id,
              'totalAmount': _totalPrice,
              'paymentMethod': 'online',
            },
          );
        }
      } else {
        _showError('Không thể đặt sân. Vui lòng thử lại.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Slot này đã được đặt. Vui lòng chọn slot khác.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onHoldExpired() {
    if (!mounted) return;
    final bookingsState = ref.read(bookingsProvider);
    if (bookingsState.activeBookingId != null) {
      ref
          .read(bookingsProvider.notifier)
          .cancelBooking(bookingsState.activeBookingId!)
          .catchError((_) {});
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hết thời gian giữ sân',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Slot đã được giải phóng. Vui lòng chọn lại.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
            child: Text(
              'Về trang chủ',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final bookingsState = ref.watch(bookingsProvider);
    final date = _slot['date'] as DateTime? ?? DateTime.now();
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Xác nhận đặt sân',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isTablet
            ? Center(
                child: SizedBox(
                  width: 520,
                  child: _buildBody(formattedDate, bookingsState),
                ),
              )
            : _buildBody(formattedDate, bookingsState),
      ),
      bottomNavigationBar: _buildBottomBar(bookingsState.isLoading),
    );
  }

  Widget _buildBody(String formattedDate, BookingsState bookingsState) {
    // Build time range: first slot start → last slot end
    final lastSlot = _slots.last;
    final startTime = _slot['startTime'] as String;
    final endTime = lastSlot['endTime'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_holdStarted && bookingsState.holdExpiresAt != null)
            HoldTimerWidget(
              expiresAt: bookingsState.holdExpiresAt!,
              onExpired: _onHoldExpired,
            ),
          if (_holdStarted && bookingsState.holdExpiresAt != null)
            const SizedBox(height: 16),
          BookingSummaryCardWidget(
            courtLabel: _court['label'] as String,
            courtNumber: _court['number'] as int,
            date: formattedDate,
            startTime: startTime,
            endTime: endTime,
            price: _totalPrice,
          ),
          const SizedBox(height: 16),
          PriceBreakdownWidget(slots: _slots),
          const SizedBox(height: 16),
          _buildPaymentMethodSelector(),
          const SizedBox(height: 16),
          const CancellationPolicyWidget(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phương thức thanh toán',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption(
            value: 'online',
            icon: Icons.credit_card_rounded,
            title: 'Thanh toán online',
            subtitle: 'Thanh toán qua cổng thanh toán điện tử',
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            value: 'cash',
            icon: Icons.payments_rounded,
            title: 'Tiền mặt (Cash)',
            subtitle: 'Thanh toán trực tiếp tại sân',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryContainer : AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.muted.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.muted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primary : AppTheme.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isLoading) {
    final isCash = _selectedPaymentMethod == 'cash';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tổng thanh toán',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatVnd(_totalPrice)} VND',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _createBookingAndPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isCash ? 'Xác nhận đặt sân' : 'Tiến hành thanh toán',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
