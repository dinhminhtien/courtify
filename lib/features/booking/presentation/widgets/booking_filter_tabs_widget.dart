import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class BookingFilterTabsWidget extends StatelessWidget {
  final TabController controller;

  const BookingFilterTabsWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.outline, width: 0.5),
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.muted,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Tất cả'),
          Tab(text: 'Sắp tới'),
          Tab(text: 'Đã hoàn tất'),
          Tab(text: 'Đã hủy'),
        ],
      ),
    );
  }
}
