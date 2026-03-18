import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AppNavTab _currentTab = AppNavTab.home;

  void _onConfirmSlots(List<Map<String, dynamic>> slots) {
    if (slots.isEmpty) return;
    final courtsState = ref.read(courtsProvider);
    if (courtsState.courts.isEmpty) return;
    final court = courtsState.courts[courtsState.selectedCourtIndex];

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
    setState(() => _currentTab = tab);
    switch (tab) {
      case AppNavTab.history:
        Navigator.pushNamed(context, AppRoutes.bookingHistory);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final courtsState = ref.watch(courtsProvider);
    final courtsNotifier = ref.read(courtsProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);

    final availableCount = courtsState.slots
        .where((s) => s.status == 'AVAILABLE')
        .length;
    final userName = currentUser?.fullName ?? 'Khách';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: isTablet
            ? _buildTabletLayout(
                userName,
                availableCount,
                courtsState,
                courtsNotifier,
              )
            : _buildPhoneLayout(
                userName,
                availableCount,
                courtsState,
                courtsNotifier,
              ),
      ),
      bottomNavigationBar: CustomerBottomNav(
        currentTab: _currentTab,
        onTabChanged: _onTabChanged,
      ),
    );
  }

  Widget _buildPhoneLayout(
    String userName,
    int availableCount,
    CourtsState courtsState,
    CourtsNotifier courtsNotifier,
  ) {
    return CustomScrollView(
      slivers: [
        HomeAppBarWidget(userName: userName, availableCount: availableCount),
        SliverToBoxAdapter(
          child: Column(
            children: [
              DateStripWidget(
                selectedDate: courtsState.selectedDate,
                onDateSelected: courtsNotifier.selectDate,
              ),
              const SizedBox(height: 12),
              CourtSelectorWidget(
                courts: courtsNotifier.courtsAsMap,
                selectedIndex: courtsState.selectedCourtIndex,
                onSelected: courtsNotifier.selectCourt,
              ),
              const SizedBox(height: 12),
              const SlotLegendWidget(),
              const SizedBox(height: 12),
              SlotGridWidget(
                slots: courtsNotifier.slotsAsMap,
                isLoading: courtsState.isLoading,
                onConfirmSlots: _onConfirmSlots,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
    String userName,
    int availableCount,
    CourtsState courtsState,
    CourtsNotifier courtsNotifier,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: CustomScrollView(
            slivers: [
              HomeAppBarWidget(
                userName: userName,
                availableCount: availableCount,
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    DateStripWidget(
                      selectedDate: courtsState.selectedDate,
                      onDateSelected: courtsNotifier.selectDate,
                    ),
                    const SizedBox(height: 12),
                    const SlotLegendWidget(),
                    const SizedBox(height: 12),
                    SlotGridWidget(
                      slots: courtsNotifier.slotsAsMap,
                      isLoading: courtsState.isLoading,
                      onConfirmSlots: _onConfirmSlots,
                      columns: 4,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: AppTheme.outline.withAlpha(77)),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const SizedBox(height: 16),
              CourtSelectorWidget(
                courts: courtsNotifier.courtsAsMap,
                selectedIndex: courtsState.selectedCourtIndex,
                onSelected: courtsNotifier.selectCourt,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
