import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import './providers/courts_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/widgets/app_navigation.dart';
import './widgets/home_app_bar_widget.dart';
import '../../courts/domain/entities/court.dart';

class HomeScreen extends ConsumerStatefulWidget {

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AppNavTab _currentTab = AppNavTab.home;

  void _onTabChanged(AppNavTab tab) {
    if (_currentTab == tab) return;
    setState(() => _currentTab = tab);
    switch (tab) {
      case AppNavTab.history:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.bookingHistory, (route) => false);
        break;
      case AppNavTab.account:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profile, (route) => false);
        break;
      case AppNavTab.booking:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.booking, (route) => false);
        break;
      case AppNavTab.home:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final courtsState = ref.watch(courtsProvider);
    final courtsNotifier = ref.read(courtsProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);

    final availableCount = courtsState.slots.where((s) => s.status == 'AVAILABLE').length;
    final userName = currentUser?.fullName ?? 'Khách';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(courtsProvider.notifier).refresh(),
          color: AppTheme.primary,
          child: isTablet
              ? _buildTabletLayout(userName, availableCount, courtsState, courtsNotifier)
              : _buildPhoneLayout(userName, availableCount, courtsState, courtsNotifier),
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
      physics: const BouncingScrollPhysics(),
      slivers: [
        HomeAppBarWidget(userName: userName, availableCount: availableCount),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppTheme.muted, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Tìm kiếm sân gần đây...',
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildBannerSlider()),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildSectionHeader('Thao tác nhanh'),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildQuickActionItem('Đặt ngay', Icons.sports_tennis_rounded, true),
                    _buildQuickActionItem('Phụ kiện', Icons.shopping_bag_rounded, false),
                    _buildQuickActionItem('Đào tạo', Icons.school_rounded, false),
                    _buildQuickActionItem('Sự kiện', Icons.event_rounded, false),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              _buildSectionHeader('Sân phổ biến'),
              const SizedBox(height: 16),
              if (courtsState.isLoading && courtsState.courts.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              else if (courtsState.error != null && courtsState.courts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Không thể tải dữ liệu sân',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                    ),
                  ),
                )
              else if (courtsState.courts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'Hiện chưa có sân nào',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.muted),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: courtsState.courts.length,
                    itemBuilder: (context, index) => 
                        _buildPopularCourtCard(courtsState.courts[index]),
                  ),
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSlider() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(40),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _onTabChanged(AppNavTab.booking),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.1,
                child: const Icon(Icons.sports_tennis_rounded, size: 180, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFFF33),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'GIẢM 20%',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đặt sân tập đầu tiên\ncủa bạn ngay hôm nay!',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
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

  Widget _buildQuickActionItem(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (label == 'Đặt ngay') _onTabChanged(AppNavTab.booking);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? AppTheme.primary : Colors.black).withAlpha(isSelected ? 60 : 10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppTheme.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularCourtCard(CourtEntity court) {
    return GestureDetector(
      onTap: () => _onTabChanged(AppNavTab.booking),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?q=80&w=400&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 16),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        court.label,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.label,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '4.8 (120+ đánh giá)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(
    String userName,
    int availableCount,
    CourtsState courtsState,
    CourtsNotifier courtsNotifier,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        HomeAppBarWidget(userName: userName, availableCount: availableCount),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: _buildBannerSlider(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Sân phổ biến'),
                const SizedBox(height: 16),
                if (courtsState.isLoading && courtsState.courts.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 260,
                    ),
                    itemCount: courtsState.courts.length,
                    itemBuilder: (context, index) =>
                        _buildPopularCourtCard(courtsState.courts[index]),
                  ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
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
