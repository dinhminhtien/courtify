import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class PayOSPaymentWidget extends StatelessWidget {
  final int amount;
  final String bookingId;
  final bool isProcessing;
  final bool isPolling;
  final VoidCallback onInitiatePayment;

  const PayOSPaymentWidget({
    super.key,
    required this.amount,
    required this.bookingId,
    required this.isProcessing,
    required this.isPolling,
    required this.onInitiatePayment,
  });

  String _formatVnd(int a) {
    final s = a.toString();
    final r = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) r.write('.');
      r.write(s[i]);
    }
    return r.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Thanh toán qua PayOS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isPolling && !isProcessing) ...[
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outline.withAlpha(102)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_rounded,
                    size: 80,
                    color: Color(0xFFBDBDBD),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR sẽ hiển thị\nsau khi xác nhận',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.muted,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PaymentMethodRow(
              icon: Icons.account_balance_rounded,
              label: 'Chuyển khoản ngân hàng',
            ),
            const SizedBox(height: 8),
            _PaymentMethodRow(
              icon: Icons.smartphone_rounded,
              label: 'Ứng dụng ngân hàng (VietQR)',
            ),
            const SizedBox(height: 8),
            _PaymentMethodRow(
              icon: Icons.credit_card_rounded,
              label: 'Thẻ ATM / Thẻ tín dụng',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onInitiatePayment,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(
                  'Mở ứng dụng ngân hàng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ] else if (isProcessing) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Đang tạo liên kết thanh toán...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withAlpha(102)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_rounded,
                    size: 100,
                    color: AppTheme.primary,
                  ),
                  Positioned(
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatVnd(amount),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quét mã QR bằng ứng dụng ngân hàng',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'hoặc',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(
                  'Mở ứng dụng ngân hàng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PaymentMethodRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.muted),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
