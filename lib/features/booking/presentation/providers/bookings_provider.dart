import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../../data/repositories/supabase_bookings_repository.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return SupabaseBookingsRepository();
});

// ─── Bookings State ───────────────────────────────────────────────────────────

class BookingsState {
  final List<Map<String, dynamic>> bookings;
  final bool isLoading;
  final String? error;
  final String? activeBookingId;
  final DateTime? holdExpiresAt;

  const BookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
    this.activeBookingId,
    this.holdExpiresAt,
  });

  BookingsState copyWith({
    List<Map<String, dynamic>>? bookings,
    bool? isLoading,
    String? error,
    String? activeBookingId,
    DateTime? holdExpiresAt,
    bool clearError = false,
    bool clearActiveBooking = false,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeBookingId: clearActiveBooking
          ? null
          : (activeBookingId ?? this.activeBookingId),
      holdExpiresAt: clearActiveBooking
          ? null
          : (holdExpiresAt ?? this.holdExpiresAt),
    );
  }
}

// ─── Bookings Notifier ────────────────────────────────────────────────────────

class BookingsNotifier extends Notifier<BookingsState> {
  BookingsRepository? _bookingsRepository;

  @override
  BookingsState build() {
    _bookingsRepository = ref.watch(bookingsRepositoryProvider);
    return const BookingsState();
  }

  Future<void> loadUserBookings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bookings = await _bookingsRepository!.getUserBookings();
      state = state.copyWith(
        bookings: bookings.map((b) => b.toDisplayMap()).toList(),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Load bookings error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAllBookings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bookings = await _bookingsRepository!.getAllBookings();
      state = state.copyWith(
        bookings: bookings.map((b) => b.toDisplayMap()).toList(),
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Load all bookings error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<BookingEntity?> createBooking({
    required List<String> slotIds,
    required String courtId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final booking = await _bookingsRepository!.createBooking(
        slotIds: slotIds,
        courtId: courtId,
      );
      if (booking != null) {
        state = state.copyWith(
          isLoading: false,
          activeBookingId: booking.id,
          holdExpiresAt:
              booking.holdExpiresAt ??
              DateTime.now().add(const Duration(minutes: 5)),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return booking;
    } catch (e) {
      debugPrint('Create booking error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _bookingsRepository!.cancelBooking(bookingId);
      await loadUserBookings();
    } catch (e) {
      debugPrint('Cancel booking error: $e');
      rethrow;
    }
  }

  Future<void> confirmBooking(String bookingId) async {
    try {
      await _bookingsRepository!.confirmBooking(bookingId);
      await loadAllBookings();
    } catch (e) {
      debugPrint('Confirm booking error: $e');
      rethrow;
    }
  }

  Future<void> completeBooking(String bookingId) async {
    try {
      await _bookingsRepository!.completeBooking(bookingId);
      await loadAllBookings();
    } catch (e) {
      debugPrint('Complete booking error: $e');
      rethrow;
    }
  }

  void clearActiveBooking() {
    state = state.copyWith(clearActiveBooking: true);
  }

  List<Map<String, dynamic>> getFilteredBookings(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return state.bookings.where((b) => b['isUpcoming'] == true).toList();
      case 2:
        return state.bookings.where((b) => b['status'] == 'COMPLETED').toList();
      case 3:
        return state.bookings.where((b) => b['status'] == 'CANCELLED').toList();
      default:
        return state.bookings;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final bookingsProvider = NotifierProvider<BookingsNotifier, BookingsState>(() {
  return BookingsNotifier();
});
