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
      bodyContent = _buildScheduleTab();

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

  Widget _buildScheduleTab() {
    final dashboardState = ref.watch(ownerDashboardProvider);
    final notifier = ref.read(ownerDashboardProvider.notifier);
    final filteredBookings = notifier.filteredBookings;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInternalHeader('Lịch đặt sân'),
            Padding(
              padding: const EdgeInsets.only(right: 20, top: 24),
              child: IconButton(
                icon: Icon(
                  Icons.calendar_month_rounded,
                  color: dashboardState.dateFilter != null 
                      ? AppTheme.primary 
                      : AppTheme.muted,
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: dashboardState.dateFilter ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  notifier.setDateFilter(date);
                },
              ),
            ),
          ],
        ),
        
        // Payment Method Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Tất cả',
                isSelected: dashboardState.paymentMethodFilter == null,
                onSelected: (s) => notifier.setPaymentFilter('All'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Tiền mặt',
                isSelected: dashboardState.paymentMethodFilter == 'cash',
                onSelected: (s) => notifier.setPaymentFilter('cash'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Online',
                isSelected: dashboardState.paymentMethodFilter == 'online',
                onSelected: (s) => notifier.setPaymentFilter('online'),
              ),
              if (dashboardState.dateFilter != null) ...[
                const SizedBox(width: 8),
                InputChip(
                  label: Text(
                    '${dashboardState.dateFilter!.day}/${dashboardState.dateFilter!.month}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onDeleted: () => notifier.setDateFilter(null),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  backgroundColor: AppTheme.primaryContainer.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),

        Expanded(
          child: filteredBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_list_off_rounded,
                          size: 64, color: AppTheme.muted.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy booking nào phù hợp',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.muted,
                          fontSize: 16,
                        ),
                      ),
                      if (dashboardState.paymentMethodFilter != null || dashboardState.dateFilter != null)
                        TextButton(
                          onPressed: () {
                            notifier.setPaymentFilter('All');
                            notifier.setDateFilter(null);
                          },
                          child: const Text('Xóa bộ lọc'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return _buildDetailedScheduleItem(booking);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.muted,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),

      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.outline.withOpacity(0.2),
        ),
      ),
    );
  }


  Widget _buildDetailedScheduleItem(Map<String, dynamic> booking) {
    final status = booking['status'] as String? ?? 'PENDING';
    final paymentStatus = booking['paymentStatus'] as String? ?? 'UNPAID';
    final price = booking['price'] as int? ?? 0;
    final isPaid = paymentStatus == 'PAID';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: status == 'PENDING' 
              ? AppTheme.warning.withOpacity(0.3) 
              : AppTheme.outline.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Top Section: Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: status == 'PENDING' 
                        ? AppTheme.secondaryContainer 
                        : AppTheme.primaryContainer,
                    child: Text(
                      booking['avatarLetter'] as String? ?? 'K',
                      style: GoogleFonts.plusJakartaSans(
                        color: status == 'PENDING' ? AppTheme.warning : AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['customerName'] as String? ?? 'Khách hàng',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF1C1B1F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.calendar_month_outlined, size: 12, color: AppTheme.muted),
                            const SizedBox(width: 4),
                            Text(
                              booking['dateFormatted'] as String? ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: AppTheme.outline.withOpacity(0.1)),
            ),

            // Middle Section: Time & Court
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    Icons.sports_tennis_rounded,
                    booking['courtLabel'] as String? ?? 'Sân',
                    AppTheme.primary,
                  ),
                  _buildInfoChip(
                    Icons.access_time_filled_rounded,
                    '${booking['startTime']} - ${booking['endTime']}',
                    AppTheme.info,
                  ),
                ],
              ),
            ),

            // Bottom Section: Payment & Price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.background.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(

                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isPaid ? AppTheme.success : AppTheme.warning,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPaid ? Icons.check_rounded : Icons.pending_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isPaid ? AppTheme.success : AppTheme.warning,
                            ),
                          ),

                          Text(
                            _translatePaymentMethod(booking['paymentMethod'] as String?),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${_formatPrice(price)} VND',

                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'CONFIRMED':
        color = AppTheme.success;
        label = 'Đã xác nhận';
        break;
      case 'COMPLETED':
        color = AppTheme.info;
        label = 'Hoàn tất';
        break;
      case 'CANCELLED':
        color = AppTheme.error;
        label = 'Đã hủy';
        break;
      default:
        color = AppTheme.warning;
        label = 'Chờ xử lý';
    }

    return _buildStatusBadgeStyle(color, label);
  }

  String _translatePaymentMethod(String? method) {
    if (method == null || method == 'CHƯA CÓ') return 'Chưa chọn';
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tiền mặt';
      case 'bank_transfer':
        return 'Chuyển khoản';
      default:
        return method;
    }
  }

  Widget _buildStatusBadgeStyle(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }


  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF1C1B1F),
          ),
        ),
      ],
    );
  }

  String _formatPrice(int amount) {
    final s = amount.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return result.toString();
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
              const OwnerQuickStatsWidget(),
              const SizedBox(height: 16),
              const OwnerKpiGridWidget(),
              const SizedBox(height: 16),
              const OwnerRevenueChartWidget(),
              const SizedBox(height: 16),
              OwnerRecentBookingsWidget(
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
                const Expanded(
                  flex: 55,
                  child: Column(
                    children: [
                      OwnerKpiGridWidget(),
                      SizedBox(height: 16),
                      OwnerRevenueChartWidget(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 45,
                  child: OwnerRecentBookingsWidget(
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
