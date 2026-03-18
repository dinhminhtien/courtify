import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class OwnerRevenueChartWidget extends StatefulWidget {
  const OwnerRevenueChartWidget({super.key});

  @override
  State<OwnerRevenueChartWidget> createState() =>
      _OwnerRevenueChartWidgetState();
}

class _OwnerRevenueChartWidgetState extends State<OwnerRevenueChartWidget> {
  int _selectedBarIndex = 6;

  // Weekly revenue data in VND (last 7 days)
  final List<Map<String, dynamic>> _weeklyData = [
    {'day': 'T2', 'revenue': 840000, 'bookings': 12},
    {'day': 'T3', 'revenue': 1120000, 'bookings': 16},
    {'day': 'T4', 'revenue': 690000, 'bookings': 9},
    {'day': 'T5', 'revenue': 1540000, 'bookings': 22},
    {'day': 'T6', 'revenue': 1260000, 'bookings': 18},
    {'day': 'T7', 'revenue': 1890000, 'bookings': 27},
    {'day': 'CN', 'revenue': 420000, 'bookings': 6},
  ];

  String _formatRevenue(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return '${(amount / 1000).toStringAsFixed(0)}k';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxRevenue = _weeklyData
        .map((d) => d['revenue'] as int)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final selectedRevenue = _weeklyData[_selectedBarIndex]['revenue'] as int;
    final selectedBookings = _weeklyData[_selectedBarIndex]['bookings'] as int;
    final selectedDay = _weeklyData[_selectedBarIndex]['day'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doanh thu 7 ngày qua',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cập nhật lúc 01:17 · 17/03/2026',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.muted,
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
                    '7 ngày',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDay,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.primary.withAlpha(179),
                        ),
                      ),
                      Text(
                        '${_formatRevenue(selectedRevenue.toDouble())} VND',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Số booking',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.primary.withAlpha(179),
                        ),
                      ),
                      Text(
                        '$selectedBookings',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
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
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: maxRevenue * 1.25,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback:
                        (FlTouchEvent event, BarTouchResponse? response) {
                          if (response != null &&
                              response.spot != null &&
                              event is FlTapUpEvent) {
                            setState(() {
                              _selectedBarIndex =
                                  response.spot!.touchedBarGroupIndex;
                            });
                          }
                        },
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.inverseSurface,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_formatRevenue(rod.toY)} VND\n${_weeklyData[groupIndex]['bookings']} booking',
                          GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: theme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _weeklyData.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _weeklyData[idx]['day'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: idx == _selectedBarIndex
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: idx == _selectedBarIndex
                                    ? AppTheme.primary
                                    : AppTheme.muted,
                              ),
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: maxRevenue / 4,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            _formatRevenue(value),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.muted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxRevenue / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(_weeklyData.length, (i) {
                    final revenue = (_weeklyData[i]['revenue'] as int)
                        .toDouble();
                    final isSelected = i == _selectedBarIndex;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: revenue,
                          width: 22,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.primary.withAlpha(77),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxRevenue * 1.25,
                            color: AppTheme.background,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
