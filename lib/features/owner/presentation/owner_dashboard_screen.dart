import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import './providers/owner_dashboard_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_navigation.dart';
import './widgets/owner_kpi_grid_widget.dart';
import './widgets/owner_quick_stats_widget.dart';
import './widgets/owner_recent_bookings_widget.dart';
import './widgets/owner_revenue_chart_widget.dart';
import '../../../shared/widgets/custom_error_widget.dart';
import '../../notifications/presentation/providers/notification_provider.dart';
import '../../courts/presentation/providers/courts_provider.dart';


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

  Future<void> _showAddCourtDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Thêm sân mới',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nhập số hiệu sân bạn muốn thêm vào hệ thống.',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.muted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Số hiệu sân',
                hintText: 'VD: 5',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.numbers_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.muted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Thêm',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty && mounted) {
      final courtNumber = int.tryParse(controller.text);
      if (courtNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập số hợp lệ')),
        );
        return;
      }

      try {
        await ref.read(courtsProvider.notifier).addCourt(courtNumber);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm Sân số $courtNumber'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể thêm sân. Vui lòng thử lại.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final dashboardState = ref.watch(ownerDashboardProvider);

    Widget bodyContent;

    if (_currentTab == OwnerNavTab.manage) {
      bodyContent = _buildManageCourtsTab();
    } else if (_currentTab == OwnerNavTab.schedule) {
      bodyContent = _buildScheduleTab(dashboardState.bookings);
    } else if (_currentTab == OwnerNavTab.settings) {
      bodyContent = _buildSettingsTab();
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

  Widget _buildManageCourtsTab() {
    final courtsState = ref.watch(courtsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý sân',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCourtDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm sân'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: courtsState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: courtsState.courts.length,
                  itemBuilder: (context, index) {
                    final court = courtsState.courts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryContainer,
                          child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.primary),
                        ),
                        title: Text(court.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Sân số ${court.courtNumber}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab(List<Map<String, dynamic>> bookings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInternalHeader('Lịch đặt sân'),
        Expanded(
          child: bookings.isEmpty
              ? const Center(child: Text('Chưa có lịch đặt nào'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(booking['customerName'] as String),
                        subtitle: Text('${booking['courtLabel']} · ${booking['startTime']}'),
                        trailing: Text(
                          booking['status'] as String,
                          style: TextStyle(
                            color: booking['status'] == 'CONFIRMED' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInternalHeader('Cài đặt'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildSettingItem('Thông tin tài khoản', Icons.person_outline),
              _buildSettingItem('Thông báo', Icons.notifications_none),
              _buildSettingItem('Bảo mật', Icons.lock_outline),
              _buildSettingItem('Trợ giúp', Icons.help_outline),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                onTap: _confirmLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInternalHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.muted),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
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
          onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppTheme.primary,
              ),
              if (ref.watch(notificationProvider).unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${ref.watch(notificationProvider).unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
