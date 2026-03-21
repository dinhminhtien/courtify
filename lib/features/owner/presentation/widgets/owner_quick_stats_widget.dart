import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/owner_dashboard_provider.dart';

class OwnerQuickStatsWidget extends ConsumerWidget {
  const OwnerQuickStatsWidget({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerDashboardProvider);
    final totalBookings = state.bookings.length;
    final totalRevenue = state.todayRevenue;
    final pendingCount = state.pendingCount;


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryLight, AppTheme.primary],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickStatItem(
              label: 'Tổng booking',
              value: '$totalBookings',
              icon: Icons.event_note_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withAlpha(77)),
          Expanded(
            child: _QuickStatItem(
              label: 'Doanh thu',
              value: _formatRevenue(totalRevenue),
              icon: Icons.attach_money_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withAlpha(77)),
          Expanded(
            child: _QuickStatItem(
              label: 'Chờ xử lý',
              value: '$pendingCount',
              icon: Icons.pending_actions_rounded,
              isAlert: pendingCount > 0,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRevenue(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return '${(amount / 1000).toStringAsFixed(0)}k';
  }
}

class _QuickStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isAlert;

  const _QuickStatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isAlert
              ? const Color(0xFFFFD54F)
              : Colors.white.withAlpha(204),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isAlert ? const Color(0xFFFFD54F) : Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.white.withAlpha(191),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
