import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import './providers/bookings_provider.dart';
import '../../../shared/widgets/app_navigation.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import './widgets/booking_filter_tabs_widget.dart';
import './widgets/booking_history_card_widget.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppNavTab _currentTab = AppNavTab.history;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    // Load bookings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsProvider.notifier).loadUserBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(bookingsProvider.notifier).loadUserBookings();
  }

  void _handleCancel(String bookingId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hủy đặt sân?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn hủy booking $bookingId không? Hành động này không thể hoàn tác.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.muted,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Không',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(bookingsProvider.notifier)
                    .cancelBooking(bookingId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã hủy đặt sân'),
                    backgroundColor: AppTheme.error,
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
                    content: Text('Không thể hủy. Vui lòng thử lại.'),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Hủy đặt sân',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTabChanged(AppNavTab tab) {
    if (_currentTab == tab) return;
    setState(() => _currentTab = tab);
    switch (tab) {
      case AppNavTab.home:
      case AppNavTab.booking:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        break;
      case AppNavTab.account:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.profile,
          (route) => false,
        );
        break;
      case AppNavTab.history:
        // Already here
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final bookingsState = ref.watch(bookingsProvider);
    final bookingsNotifier = ref.read(bookingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        automaticallyImplyLeading: false,
        title: Text(
          'Lịch sử đặt sân',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: _handleRefresh,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: BookingFilterTabsWidget(controller: _tabController),
        ),
      ),
      body: SafeArea(
        top: false,
        child: bookingsState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : TabBarView(
                controller: _tabController,
                children: List.generate(4, (tabIdx) {
                  final bookings = bookingsNotifier.getFilteredBookings(tabIdx);
                  if (bookings.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.event_busy_rounded,
                      title: 'Chưa có đặt sân nào',
                      description:
                          'Bạn chưa có lịch đặt sân nào trong mục này.\nHãy đặt sân để bắt đầu chơi!',
                      actionLabel: 'Đặt sân ngay',
                      onAction: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (route) => false,
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: _handleRefresh,
                    child: isTablet
                        ? _buildTabletList(bookings)
                        : _buildPhoneList(bookings),
                  );
                }),
              ),
      ),
      bottomNavigationBar: CustomerBottomNav(
        currentTab: _currentTab,
        onTabChanged: _onTabChanged,
      ),
    );
  }

  Widget _buildPhoneList(List<Map<String, dynamic>> bookings) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 400)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 16 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: BookingHistoryCardWidget(
            booking: booking,
            onCancel:
                (booking['status'] == 'PENDING' ||
                    (booking['status'] == 'CONFIRMED' &&
                        booking['isUpcoming'] == true))
                ? () => _handleCancel(booking['id'])
                : null,
            onPayNow:
                booking['status'] == 'PENDING' &&
                    booking['paymentStatus'] == 'UNPAID'
                ? () => Navigator.pushNamed(
                    context,
                    AppRoutes.payment,
                    arguments: {
                      'slot': {
                        'startTime': booking['startTime'],
                        'endTime': booking['endTime'],
                        'price': booking['price'],
                        'date': DateTime.now(),
                      },
                      'court': {
                        'number': booking['courtNumber'],
                        'label': booking['courtLabel'],
                      },
                      'bookingId': booking['id'],
                      'totalAmount': booking['price'],
                      'holdExpiresAt': DateTime.now().add(
                        const Duration(minutes: 5),
                      ),
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildTabletList(List<Map<String, dynamic>> bookings) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingHistoryCardWidget(
          booking: booking,
          onCancel:
              (booking['status'] == 'PENDING' ||
                  (booking['status'] == 'CONFIRMED' &&
                      booking['isUpcoming'] == true))
              ? () => _handleCancel(booking['id'])
              : null,
          onPayNow: null,
        );
      },
    );
  }
}
