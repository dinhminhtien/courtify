import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class PriceBreakdownWidget extends StatelessWidget {
  final List<Map<String, dynamic>> slots;

  const PriceBreakdownWidget({
    super.key,
    required this.slots,
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
    final total = slots.fold(0, (sum, s) => sum + (s['price'] as int));

    return Container(
      padding: const EdgeInsets.all(18),
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
            'Chi tiết giá',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...slots.map((slot) {
            final startTime = (slot['startTime'] as String).substring(0, 5);
            final endTime = (slot['endTime'] as String).substring(0, 5);
            final price = slot['price'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PriceRow(
                label: 'Khung giờ $startTime – $endTime',
                value: '${_formatVnd(price)} VND',
                isLight: true,
              ),
            );
          }),
          const SizedBox(height: 4),
          _PriceRow(label: 'Giảm giá', value: '0 VND', isLight: true),
          const SizedBox(height: 12),
          Container(height: 1, color: AppTheme.outline.withAlpha(77)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Tổng cộng',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatVnd(total)} VND',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 14,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Hoàn tiền 100% nếu hủy trước 2 giờ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLight;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isLight ? AppTheme.muted : const Color(0xFF1C1B1F),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
