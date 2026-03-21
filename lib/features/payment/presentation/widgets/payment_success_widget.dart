import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class PaymentSuccessWidget extends StatefulWidget {
  final String bookingId;
  final String courtLabel;
  final String date;
  final String startTime;
  final String endTime;
  final int totalAmount;
  final String paymentMethod;
  final VoidCallback onViewBookings;
  final VoidCallback onGoHome;

  const PaymentSuccessWidget({
    super.key,
    required this.bookingId,
    required this.courtLabel,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    this.paymentMethod = 'online',
    required this.onViewBookings,
    required this.onGoHome,
  });

  @override
  State<PaymentSuccessWidget> createState() => _PaymentSuccessWidgetState();
}

class _PaymentSuccessWidgetState extends State<PaymentSuccessWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutBack,
    );
    Future.delayed(
      const Duration(milliseconds: 200),
      () => _checkController.forward(),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
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

  bool get _isCash => widget.paymentMethod == 'cash';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          ScaleTransition(
            scale: _checkScale,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _isCash
                    ? const Color(0xFFFFF8E1)
                    : AppTheme.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isCash ? const Color(0xFFFF8F00) : AppTheme.primary)
                            .withAlpha(51),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isCash ? Icons.payments_rounded : Icons.check_rounded,
                color: _isCash ? const Color(0xFFFF8F00) : AppTheme.primary,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isCash ? 'Đặt sân thành công!' : 'Thanh toán thành công!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isCash
                ? 'Vui lòng thanh toán tiền mặt tại sân'
                : 'Booking của bạn đã được xác nhận',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.muted,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isCash) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF8F00).withAlpha(100),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFFF8F00),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Thanh toán tiền mặt khi đến sân',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFFFF8F00),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ReceiptRow(label: 'Mã đặt sân', value: widget.bookingId),
                const SizedBox(height: 10),
                _ReceiptRow(label: 'Sân', value: widget.courtLabel),
                const SizedBox(height: 10),
                _ReceiptRow(label: 'Ngày', value: widget.date),
                const SizedBox(height: 10),
                _ReceiptRow(
                  label: 'Giờ chơi',
                  value: '${widget.startTime} – ${widget.endTime}',
                ),
                const SizedBox(height: 10),
                _ReceiptRow(
                  label: 'Thanh toán',
                  value: _isCash ? 'Tiền mặt tại sân' : 'Online',
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: AppTheme.primary.withAlpha(51)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      _isCash ? 'Số tiền cần trả' : 'Đã thanh toán',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_formatVnd(widget.totalAmount)} VND',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.onViewBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Xem lịch đặt sân',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: widget.onGoHome,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Về trang chủ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
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

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.primary.withAlpha(179),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
