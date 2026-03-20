import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

import '../../../booking/domain/repositories/bookings_repository.dart';
import '../../../booking/presentation/providers/bookings_provider.dart';

// ─── Owner Dashboard State ────────────────────────────────────────────────────

class OwnerDashboardState {
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> weeklyRevenue;
  final bool isLoading;
  final String? error;

  const OwnerDashboardState({
    this.bookings = const [],
    this.weeklyRevenue = const [],
    this.isLoading = false,
    this.error,
  });

  OwnerDashboardState copyWith({
    List<Map<String, dynamic>>? bookings,
    List<Map<String, dynamic>>? weeklyRevenue,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OwnerDashboardState(
      bookings: bookings ?? this.bookings,
      weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
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
      
      // Calculate weekly revenue
      final now = DateTime.now();
      final recentBookings = bookingsMap.where((b) {
        if (b['createdAt'] == null) return false;
        final createdAt = DateTime.tryParse(b['createdAt'] as String);
        if (createdAt == null) return false;
        // Last 7 days including today
        return now.difference(createdAt).inDays <= 7;
      }).toList();

      final List<Map<String, dynamic>> weeklyRevenue = [];
      const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        
        int dayRevenue = 0;
        int dayBookingsCount = 0;
        
        for (var b in recentBookings) {
          final createdAt = DateTime.tryParse(b['createdAt'] as String);
          if (createdAt != null &&
              createdAt.year == date.year &&
              createdAt.month == date.month &&
              createdAt.day == date.day) {
            
            dayBookingsCount++;
            if (b['paymentStatus'] == 'PAID') {
              dayRevenue += (b['price'] as int?) ?? 0;
            }
          }
        }
        
        // get 1-based weekday index (1=Monday, 7=Sunday)
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
}

// ─── Providers ────────────────────────────────────────────────────────────────

final ownerDashboardProvider =
    NotifierProvider<OwnerDashboardNotifier, OwnerDashboardState>(() {
      return OwnerDashboardNotifier();
    });
