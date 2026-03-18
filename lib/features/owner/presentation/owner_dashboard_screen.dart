import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../payment/presentation/providers/payment_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/widgets/app_navigation.dart';
import './widgets/owner_kpi_grid_widget.dart';
import './widgets/owner_quick_stats_widget.dart';
import './widgets/owner_recent_bookings_widget.dart';
import './widgets/owner_revenue_chart_widget.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  OwnerNavTab _currentTab = OwnerNavTab.dashboard;

  void _handleConfirmBooking(String bookingId) async {
    try {
      await ref.read(ownerDashboardProvider.notifier).confirmBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xác nhận booking'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xác nhận. Vui lòng thử lại.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleCompleteBooking(String bookingId) async {
    try {
      await ref
          .read(ownerDashboardProvider.notifier)
          .completeBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã hoàn tất booking'),
          backgroundColor: AppTheme.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể hoàn tất. Vui lòng thử lại.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onTabChanged(OwnerNavTab tab) {
    setState(() => _currentTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final dashboardState = ref.watch(ownerDashboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () =>
              ref.read(ownerDashboardProvider.notifier).loadDashboardData(),
          child: dashboardState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : isTablet
              ? _buildTabletLayout(dashboardState.bookings)
              : _buildPhoneLayout(dashboardState.bookings),
        ),
      ),
      bottomNavigationBar: OwnerBottomNav(
        currentTab: _currentTab,
        onTabChanged: _onTabChanged,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.lock_outline_rounded, size: 20),
        label: Text(
          'Khóa Slot',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildPhoneLayout(List<Map<String, dynamic>> bookings) {
    return CustomScrollView(
      slivers: [
        _buildOwnerAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              OwnerQuickStatsWidget(bookings: bookings),
              const SizedBox(height: 16),
              OwnerKpiGridWidget(bookings: bookings),
              const SizedBox(height: 16),
              OwnerRevenueChartWidget(),
              const SizedBox(height: 16),
              OwnerRecentBookingsWidget(
                bookings: bookings,
                onConfirm: _handleConfirmBooking,
                onComplete: _handleCompleteBooking,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(List<Map<String, dynamic>> bookings) {
    return CustomScrollView(
      slivers: [
        _buildOwnerAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 55,
                  child: Column(
                    children: [
                      OwnerKpiGridWidget(bookings: bookings),
                      const SizedBox(height: 16),
                      OwnerRevenueChartWidget(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 45,
                  child: OwnerRecentBookingsWidget(
                    bookings: bookings,
                    onConfirm: _handleConfirmBooking,
                    onComplete: _handleCompleteBooking,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerAppBar() {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final currentUser = ref.watch(currentUserProvider);
    final ownerInitial = (currentUser?.fullName?.isNotEmpty == true)
        ? currentUser!.fullName![0].toUpperCase()
        : 'O';

    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      pinned: true,
      expandedHeight: 110,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng quan hôm nay',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sân Cầu Lông Courtify',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          dateStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      title: Text(
        'Tổng quan',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
      titleSpacing: 20,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppTheme.primary,
          ),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: AppTheme.primary,
            child: Text(
              ownerInitial,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
