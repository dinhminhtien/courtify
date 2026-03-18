import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import './providers/payment_provider.dart';
import '../../booking/presentation/providers/bookings_provider.dart';
import './widgets/payment_booking_summary_widget.dart';
import './widgets/payment_countdown_widget.dart';
import './widgets/payment_success_widget.dart';
import './widgets/payos_payment_widget.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? paymentArgs;

  const PaymentScreen({super.key, this.paymentArgs});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with SingleTickerProviderStateMixin {
  Timer? _pollingTimer;

  late AnimationController _successController;
  late Animation<double> _successScale;

  late Map<String, dynamic> _slot;
  late Map<String, dynamic> _court;
  late String _bookingId;
  late int _totalAmount;
  late String _paymentMethod;
  late String _startTime;
  late String _endTime;
  late List<Map<String, dynamic>> _slots;
  DateTime? _holdExpiresAt;

  @override
  void initState() {
    super.initState();
    final args = widget.paymentArgs;
    _slot =
        args?['slot'] as Map<String, dynamic>? ??
        {
          'startTime': '09:00',
          'endTime': '10:00',
          'price': 60000,
          'date': DateTime.now(),
        };
    _court =
        args?['court'] as Map<String, dynamic>? ??
        {'number': 3, 'label': 'Sân 3'};
    _bookingId =
        args?['bookingId'] as String? ??
        'BK-${DateTime.now().millisecondsSinceEpoch}';
    final slotsArg = args?['slots'] as List<dynamic>?;
    if (slotsArg != null && slotsArg.isNotEmpty) {
      _slots = slotsArg.cast<Map<String, dynamic>>();
    } else {
      _slots = [_slot];
    }
    _totalAmount = args?['totalAmount'] as int? ?? _slots.fold(0, (sum, s) => sum + (s['price'] as int));
    _paymentMethod = args?['paymentMethod'] as String? ?? 'online';
    _holdExpiresAt = args?['holdExpiresAt'] as DateTime?;

    // Determine start and end times for summary
    final lastSlot = _slots.last;
    _startTime = _slots.first['startTime'] as String;
    _endTime = lastSlot['endTime'] as String;

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOutBack,
    );

    // For cash payments, trigger success animation immediately
    if (_paymentMethod == 'cash') {
      Future.microtask(() {
        if (mounted) _successController.forward();
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    await ref
        .read(paymentProvider.notifier)
        .initiatePayment(bookingId: _bookingId, amount: _totalAmount);
    _startPolling();
  }

  void _startPolling() {
    int count = 0;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      count++;
      if (count >= 4) {
        timer.cancel();
        if (mounted) _onPaymentConfirmed();
      }
    });
  }

  void _onPaymentConfirmed() async {
    final slotIds = _slots.map((s) => s['id'] as String).toList();
    await ref
        .read(paymentProvider.notifier)
        .confirmPayment(bookingId: _bookingId, slotIds: slotIds);
    if (!mounted) return;
    _successController.forward();
  }

  void _handleHoldExpired() {
    _pollingTimer?.cancel();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hết thời gian thanh toán',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Slot đã được giải phóng do quá thời gian giữ. Vui lòng chọn lại.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.muted,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Về trang chủ',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hủy thanh toán?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Nếu hủy, slot sẽ được giải phóng và booking sẽ bị hủy.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.muted,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tiếp tục thanh toán',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              _pollingTimer?.cancel();
              Navigator.pop(context);
              try {
                await ref
                    .read(bookingsProvider.notifier)
                    .cancelBooking(_bookingId);
              } catch (_) {}
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
            child: Text(
              'Hủy booking',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.error,
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
    final paymentState = ref.watch(paymentProvider);

    // Show success screen for cash payments immediately, or after online payment confirmed
    final showSuccess = _paymentMethod == 'cash'
        ? paymentState.paymentSuccess
        : paymentState.paymentSuccess;

    if (showSuccess) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ScaleTransition(
            scale: _successScale,
            child: PaymentSuccessWidget(
              bookingId: _bookingId,
              courtLabel: _court['label'] as String,
              date: _slot['date'] is DateTime
                  ? '${(_slot['date'] as DateTime).day.toString().padLeft(2, '0')}/${(_slot['date'] as DateTime).month.toString().padLeft(2, '0')}/${(_slot['date'] as DateTime).year}'
                  : 'Hôm nay',
              startTime: _startTime,
              endTime: _endTime,
              totalAmount: _totalAmount,
              paymentMethod: _paymentMethod,
              onViewBookings: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.bookingHistory,
                (route) => false,
              ),
              onGoHome: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              ),
            ),
          ),
        ),
      );
    }

    // Cash payment should never reach here (success shown immediately)
    // Only show payment UI for online method
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primary),
          onPressed: _handleCancel,
        ),
        title: Text(
          'Thanh toán',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_holdExpiresAt != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PaymentCountdownWidget(
                expiresAt: _holdExpiresAt!,
                onExpired: _handleHoldExpired,
                compact: true,
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: isTablet
            ? Center(
                child: SizedBox(width: 520, child: _buildBody(paymentState)),
              )
            : _buildBody(paymentState),
      ),
    );
  }

  Widget _buildBody(PaymentState paymentState) {
    final date = _slot['date'] is DateTime
        ? '${(_slot['date'] as DateTime).day.toString().padLeft(2, '0')}/${(_slot['date'] as DateTime).month.toString().padLeft(2, '0')}/${(_slot['date'] as DateTime).year}'
        : 'Hôm nay';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PaymentBookingSummaryWidget(
            bookingId: _bookingId,
            courtLabel: _court['label'] as String,
            date: date,
            startTime: _startTime,
            endTime: _endTime,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số tiền cần thanh toán',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatVnd(_totalAmount)} VND',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PayOS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PayOSPaymentWidget(
            amount: _totalAmount,
            bookingId: _bookingId,
            isProcessing: paymentState.isProcessing,
            isPolling: paymentState.isPolling,
            onInitiatePayment: _initiatePayment,
          ),
          if (paymentState.isPolling) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success.withAlpha(77)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đang chờ xác nhận thanh toán từ ngân hàng...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: BorderSide(color: AppTheme.error.withAlpha(128)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Hủy thanh toán',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
