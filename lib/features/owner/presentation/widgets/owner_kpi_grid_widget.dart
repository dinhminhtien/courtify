import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class OwnerKpiGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;

  const OwnerKpiGridWidget({super.key, required this.bookings});

  @override
  Widget build(BuildContext context) {
    final confirmedCount = bookings
        .where((b) => b['status'] == 'CONFIRMED')
        .length;
    final pendingCount = bookings.where((b) => b['status'] == 'PENDING').length;
    final paidBookings = bookings
        .where((b) => b['paymentStatus'] == 'PAID')
        .toList();
    final todayRevenue = paidBookings.fold<int>(
      0,
      (sum, b) => sum + (b['price'] as int),
    );
    final utilizationPct =
        ((confirmedCount +
                    bookings.where((b) => b['status'] == 'COMPLETED').length) /
                (6 * 18) *
                100)
            .clamp(0, 100)
            .toStringAsFixed(0);

    final kpis = [
      {
        'label': 'Doanh thu hôm nay',
        'value': _formatRevenue(todayRevenue),
        'unit': 'VND',
        'icon': Icons.payments_rounded,
        'color': AppTheme.success,
        'bgColor': AppTheme.primaryContainer,
        'trend': '+12%',
        'trendUp': true,
      },
      {
        'label': 'Chờ xác nhận',
        'value': '$pendingCount',
        'unit': 'booking',
        'icon': Icons.hourglass_empty_rounded,
        'color': AppTheme.warning,
        'bgColor': AppTheme.secondaryContainer,
        'trend': pendingCount > 2 ? 'Cần xử lý' : 'Ổn định',
        'trendUp': pendingCount <= 2,
      },
      {
        'label': 'Đã xác nhận',
        'value': '$confirmedCount',
        'unit': 'booking',
        'icon': Icons.check_circle_rounded,
        'color': AppTheme.info,
        'bgColor': const Color(0xFFE3F2FD),
        'trend': '+$confirmedCount',
        'trendUp': true,
      },
      {
        'label': 'Tỷ lệ lấp đầy',
        'value': utilizationPct,
        'unit': '%',
        'icon': Icons.bar_chart_rounded,
        'color': AppTheme.primary,
        'bgColor': AppTheme.primaryContainer,
        'trend': 'Hôm nay',
        'trendUp': true,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chỉ số hôm nay',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemCount: kpis.length,
            itemBuilder: (context, i) {
              final kpi = kpis[i];
              return _KpiCard(
                label: kpi['label'] as String,
                value: kpi['value'] as String,
                unit: kpi['unit'] as String,
                icon: kpi['icon'] as IconData,
                color: kpi['color'] as Color,
                bgColor: kpi['bgColor'] as Color,
                trend: kpi['trend'] as String,
                trendUp: kpi['trendUp'] as bool,
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatRevenue(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '$amount';
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String trend;
  final bool trendUp;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendUp
                      ? AppTheme.primaryContainer
                      : AppTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp
                          ? Icons.trending_up_rounded
                          : Icons.priority_high_rounded,
                      size: 10,
                      color: trendUp ? AppTheme.success : AppTheme.warning,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: trendUp ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.muted,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
