import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../booking/domain/repositories/bookings_repository.dart';
import '../../../booking/presentation/providers/bookings_provider.dart';

// ─── Owner Dashboard State ────────────────────────────────────────────────────

class OwnerDashboardState {
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> weeklyRevenue;
  final int todayRevenue;
  final int potentialRevenue;
  final int yesterdayRevenue;
  final int pendingCount;
  final int confirmedCount;
  final double utilizationPct;
  final bool isLoading;
  final String? error;
  final String? paymentMethodFilter;
  final DateTime? dateFilter;


  const OwnerDashboardState({
    this.bookings = const [],
    this.weeklyRevenue = const [],
    this.todayRevenue = 0,
    this.potentialRevenue = 0,
    this.yesterdayRevenue = 0,
    this.pendingCount = 0,
    this.confirmedCount = 0,
    this.utilizationPct = 0,
    this.isLoading = false,
    this.error,
    this.paymentMethodFilter,
    this.dateFilter,
  });


  OwnerDashboardState copyWith({
    List<Map<String, dynamic>>? bookings,
    List<Map<String, dynamic>>? weeklyRevenue,
    int? todayRevenue,
    int? potentialRevenue,
    int? yesterdayRevenue,
    int? pendingCount,
    int? confirmedCount,
    double? utilizationPct,
    bool? isLoading,
    String? error,
    String? paymentMethodFilter,
    DateTime? dateFilter,
    bool clearError = false,
    bool clearDate = false,
    bool clearPaymentFilter = false,
  }) {
    return OwnerDashboardState(
      bookings: bookings ?? this.bookings,
      weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      potentialRevenue: potentialRevenue ?? this.potentialRevenue,
      yesterdayRevenue: yesterdayRevenue ?? this.yesterdayRevenue,
      pendingCount: pendingCount ?? this.pendingCount,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      utilizationPct: utilizationPct ?? this.utilizationPct,
      paymentMethodFilter: clearPaymentFilter ? null : (paymentMethodFilter ?? this.paymentMethodFilter),
      dateFilter: clearDate ? null : (dateFilter ?? this.dateFilter),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }


}


// ─── Owner Dashboard Notifier ─────────────────────────────────────────────────

class OwnerDashboardNotifier extends Notifier<OwnerDashboardState> {
  BookingsRepository? _bookingsRepository;

  @override
  OwnerDashboardState build() {
    _bookingsRepository = ref.watch(bookingsRepositoryProvider);
    
    // Watch user to trigger reload when login state changes
    final user = ref.watch(currentUserProvider);
    if (user != null && user.isOwner) {
      Future.microtask(() => loadDashboardData());
      return const OwnerDashboardState(isLoading: true);
    }
    
    return const OwnerDashboardState();
  }


  Future<void> loadDashboardData() async {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isOwner) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rawBookings = await _bookingsRepository!.getAllBookings();
      final bookingsMap = rawBookings.map((b) => b.toDisplayMap()).toList();
      
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      // ─── Stats Phase ────────────────────────────────────────────────────────
      int todayRevenue = 0;
      int potentialRevenue = 0;
      int yesterdayRevenue = 0;
      int pendingCount = 0;
      int confirmedCount = 0;
      int totalTodaySlotsUsed = 0;

      for (var b in bookingsMap) {
        final createdAtStr = b['createdAt'] as String? ?? '';
        final createdAt = DateTime.tryParse(createdAtStr);
        
        final slotDateStr = b['date'] as String? ?? '';
        // Date format from toDisplayMap is dd/MM/yyyy. Need to parse it.
        DateTime? bookingDate;
        if (slotDateStr.isNotEmpty) {
          final parts = slotDateStr.split('/');
          if (parts.length == 3) {
            bookingDate = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
          }
        }
        
        final isToday = bookingDate != null && 
                        bookingDate.year == now.year && 
                        bookingDate.month == now.month && 
                        bookingDate.day == now.day;
        
        final createdYesterday = createdAt != null &&
                                createdAt.year == yesterday.year && 
                                createdAt.month == yesterday.month && 
                                createdAt.day == yesterday.day;

        // Count pending/confirmed regardless of creation date (for current active dashboard)
        if (isToday) {
          if (b['status'] == 'PENDING') pendingCount++;
          if (b['status'] == 'CONFIRMED') confirmedCount++;
          if (b['status'] == 'CONFIRMED' || b['status'] == 'COMPLETED') totalTodaySlotsUsed++;
          
          if (b['paymentStatus'] == 'PAID') {
            todayRevenue += (b['price'] as int?) ?? 0;
          } else if (b['status'] == 'CONFIRMED') {
            potentialRevenue += (b['price'] as int?) ?? 0;
          }
        }

        // For trend calculation: revenue from bookings created yesterday vs today
        if (createdYesterday && b['paymentStatus'] == 'PAID') {
          yesterdayRevenue += (b['price'] as int?) ?? 0;
        }
      }

      // ─── Utilization Calculation ────────────────────────────────────────────
      // Capacity formula: Total Courts * Daily Slots. 
      // Using 6 courts * 18 slots = 108 as logic base (should be dynamic eventually)
      const totalExpectedCapacity = 108; 
      final utilizationPct = totalExpectedCapacity > 0 
          ? (totalTodaySlotsUsed / totalExpectedCapacity) * 100 
          : 0.0;

      // ─── Weekly Revenue Calculation ─────────────────────────────────────────
      final List<Map<String, dynamic>> weeklyRevenue = [];
      const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        int dayRevenue = 0;
        int dayBookingsCount = 0;
        
        for (var b in rawBookings) {
          final bDate = b.slot?.slotDate ?? b.createdAt;
          if (bDate != null &&
              bDate.year == date.year &&
              bDate.month == date.month &&
              bDate.day == date.day) {
            
            dayBookingsCount++;
            if (b.paymentStatus == 'PAID') {
              dayRevenue += b.slot?.price ?? 0;
            }
          }
        }
        
        final dayName = weekdays[date.weekday - 1];
        weeklyRevenue.add({
          'day': dayName,
          'revenue': dayRevenue,
          'bookings': dayBookingsCount,
        });
      }

      state = state.copyWith(
        bookings: bookingsMap,
        weeklyRevenue: weeklyRevenue,
        todayRevenue: todayRevenue,
        potentialRevenue: potentialRevenue,
        yesterdayRevenue: yesterdayRevenue,
        pendingCount: pendingCount,
        confirmedCount: confirmedCount,
        utilizationPct: utilizationPct,
        isLoading: false,
      );

    } catch (e) {
      debugPrint('Load dashboard error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> confirmBooking(String bookingId) async {
    await _bookingsRepository!.confirmBooking(bookingId);
    await loadDashboardData();
  }

  Future<void> completeBooking(String bookingId) async {
    await _bookingsRepository!.completeBooking(bookingId);
    await loadDashboardData();
  }

  void setPaymentFilter(String? method) {
    if (method == 'All') {
      state = state.copyWith(clearPaymentFilter: true);
    } else {
      state = state.copyWith(paymentMethodFilter: method);
    }
  }

  void setDateFilter(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearDate: true);
    } else {
      state = state.copyWith(dateFilter: date);
    }
  }

  List<Map<String, dynamic>> get filteredBookings {
    var list = state.bookings;
    
    // Apply Payment Method Filter
    if (state.paymentMethodFilter != null) {
      list = list.where((b) {
        final method = (b['paymentMethod'] as String? ?? '').toLowerCase();
        final filter = state.paymentMethodFilter!.toLowerCase();
        
        if (filter == 'cash') return method == 'cash';
        if (filter == 'online' || filter == 'onl') return method == 'online' || method == 'bank_transfer';
        return method.contains(filter);
      }).toList();
    }
    
    // Apply Date Filter
    if (state.dateFilter != null) {
      final filterDateStr = 
          '${state.dateFilter!.day.toString().padLeft(2, '0')}/${state.dateFilter!.month.toString().padLeft(2, '0')}/${state.dateFilter!.year}';
      list = list.where((b) => b['date'] == filterDateStr).toList();
    }
    
    return list;
  }
}


// ─── Providers ────────────────────────────────────────────────────────────────

final ownerDashboardProvider =
    NotifierProvider<OwnerDashboardNotifier, OwnerDashboardState>(() {
      return OwnerDashboardNotifier();
    });
