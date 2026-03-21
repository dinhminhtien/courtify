import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/owner_dashboard_provider.dart';

class OwnerKpiGridWidget extends ConsumerWidget {
  const OwnerKpiGridWidget({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerDashboardProvider);
    
    // Calculate trend percentage for revenue
    String revenueTrend = '0%';
    bool revenueTrendUp = true;
    if (state.yesterdayRevenue > 0) {
      final diff = state.todayRevenue - state.yesterdayRevenue;
      final pct = (diff / state.yesterdayRevenue * 100).round();
      revenueTrend = '${pct > 0 ? '+' : ''}$pct%';
      revenueTrendUp = pct >= 0;
    } else if (state.todayRevenue > 0) {
      revenueTrend = '+100%';
      revenueTrendUp = true;
    }

    final kpis = [
      {
        'label': 'Doanh thu hôm nay',
        'value': _formatRevenue(state.todayRevenue),
        'unit': 'VND',
        'icon': Icons.payments_rounded,
        'color': AppTheme.success,
        'bgColor': AppTheme.primaryContainer,
        'trend': revenueTrend,
        'trendUp': revenueTrendUp,
      },
      {
        'label': 'Doanh thu dự kiến',
        'value': _formatRevenue(state.potentialRevenue),
        'unit': 'VND',
        'icon': Icons.account_balance_wallet_rounded,
        'color': AppTheme.info,
        'bgColor': const Color(0xFFE3F2FD),
        'trend': 'Đã xác nhận',
        'trendUp': true,
      },
      {
        'label': 'Chờ xác nhận',
        'value': '${state.pendingCount}',
        'unit': 'booking',
        'icon': Icons.hourglass_empty_rounded,
        'color': AppTheme.warning,
        'bgColor': AppTheme.secondaryContainer,
        'trend': state.pendingCount > 0 ? 'Cần xử lý' : 'Hoàn tất',
        'trendUp': state.pendingCount == 0,
      },
      {
        'label': 'Tỷ lệ lấp đầy',
        'value': state.utilizationPct.toStringAsFixed(0),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kpis.map((kpi) {
                  return SizedBox(
                    width: itemWidth,
                    height: itemWidth * 0.65,
                    child: _KpiCard(
                      label: kpi['label'] as String,
                      value: kpi['value'] as String,
                      unit: kpi['unit'] as String,
                      icon: kpi['icon'] as IconData,
                      color: kpi['color'] as Color,
                      bgColor: kpi['bgColor'] as Color,
                      trend: kpi['trend'] as String,
                      trendUp: kpi['trendUp'] as bool,
                    ),
                  );
                }).toList(),
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
