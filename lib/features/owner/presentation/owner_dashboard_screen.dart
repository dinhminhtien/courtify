import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../payment/presentation/providers/payment_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_navigation.dart';
import './widgets/owner_kpi_grid_widget.dart';
import './widgets/owner_quick_stats_widget.dart';
import './widgets/owner_recent_bookings_widget.dart';
import './widgets/owner_revenue_chart_widget.dart';
import '../../../shared/widgets/custom_error_widget.dart';

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

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Đăng xuất',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc muốn đăng xuất không?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.signUpLogin, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final dashboardState = ref.watch(ownerDashboardProvider);

    Widget bodyContent;

    if (_currentTab == OwnerNavTab.manage) {
      bodyContent = _buildPlaceholderBody(
        'Quản lý sân',
        Icons.manage_accounts_rounded,
      );
    } else if (_currentTab == OwnerNavTab.schedule) {
      bodyContent = _buildPlaceholderBody(
        'Lịch đặt sân',
        Icons.calendar_month_rounded,
      );
    } else if (_currentTab == OwnerNavTab.settings) {
      bodyContent = _buildPlaceholderBody('Cài đặt', Icons.settings_rounded);
    } else if (dashboardState.error != null) {
      bodyContent = CustomErrorWidget(errorMessage: dashboardState.error);
    } else {
      bodyContent = RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () =>
            ref.read(ownerDashboardProvider.notifier).loadDashboardData(),
        child: dashboardState.isLoading && dashboardState.bookings.isEmpty
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
              )
            : dashboardState.error != null
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: CustomErrorWidget(errorMessage: dashboardState.error),
              )
            : isTablet
            ? _buildTabletLayout(dashboardState.bookings)
            : _buildPhoneLayout(dashboardState.bookings),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: bodyContent),
      bottomNavigationBar: OwnerBottomNav(
        currentTab: _currentTab,
        onTabChanged: _onTabChanged,
      ),
      floatingActionButton: _currentTab == OwnerNavTab.dashboard
          ? FloatingActionButton.extended(
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
            )
          : null,
    );
  }

  Widget _buildPlaceholderBody(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.primary.withAlpha(100)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tính năng đang phát triển',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.muted,
            ),
          ),
        ],
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
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppTheme.primary,
          ),
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          icon: const Icon(
            Icons.logout_rounded,
            color: AppTheme.primary,
            size: 22,
          ),
          onPressed: _confirmLogout,
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
