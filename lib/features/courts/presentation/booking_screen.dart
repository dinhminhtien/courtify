import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import './providers/courts_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/widgets/app_navigation.dart';
import './widgets/court_selector_widget.dart';
import './widgets/date_strip_widget.dart';
import './widgets/home_app_bar_widget.dart';
import './widgets/slot_grid_widget.dart';
import './widgets/slot_legend_widget.dart';
import '../../auth/presentation/widgets/update_profile_dialog.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  AppNavTab _currentTab = AppNavTab.booking;

  void _onConfirmSlots(List<Map<String, dynamic>> slots) async {
    if (slots.isEmpty) return;
    final currentUser = ref.read(currentUserProvider);

    if (currentUser?.isProfileComplete != true) {
      final updated = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const UpdateProfileDialog(),
      );
      if (updated != true) return;
    }

    final courtsState = ref.read(courtsProvider);
    if (courtsState.courts.isEmpty) return;
    final court = courtsState.courts[courtsState.selectedCourtIndex];

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      AppRoutes.bookingConfirmation,
      arguments: {
        'slots': slots,
        'slot': slots.first,
        'court': {
          'id': court.id,
          'number': court.courtNumber,
          'label': court.label,
        },
      },
    );
  }

  void _onTabChanged(AppNavTab tab) {
    if (_currentTab == tab) return;
    setState(() => _currentTab = tab);
    switch (tab) {
      case AppNavTab.home:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
        break;
      case AppNavTab.history:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.bookingHistory, (route) => false);
        break;
      case AppNavTab.account:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profile, (route) => false);
        break;
      case AppNavTab.booking:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courtsState = ref.watch(courtsProvider);
    final courtsNotifier = ref.read(courtsProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);
    final availableCount = courtsState.slots.where((s) => s.status == 'AVAILABLE').length;
    final userName = currentUser?.fullName ?? 'Khách';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            HomeAppBarWidget(userName: userName, availableCount: availableCount),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Chọn ngày'),
                    const SizedBox(height: 12),
                    DateStripWidget(
                      selectedDate: courtsState.selectedDate,
                      onDateSelected: courtsNotifier.selectDate,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Chọn sân'),
                    const SizedBox(height: 12),
                    CourtSelectorWidget(
                      courts: courtsNotifier.courtsAsMap,
                      selectedIndex: courtsState.selectedCourtIndex,
                      onSelected: courtsNotifier.selectCourt,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Thời gian và trạng thái'),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SlotLegendWidget(),
                    ),
                    const SizedBox(height: 16),
                    SlotGridWidget(
                      slots: courtsNotifier.slotsAsMap,
                      isLoading: courtsState.isLoading,
                      onConfirmSlots: _onConfirmSlots,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomerBottomNav(
        currentTab: _currentTab,
        onTabChanged: _onTabChanged,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1C1B1F),
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
