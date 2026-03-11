import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courtify/domain/entities/booking.dart';
import 'package:courtify/data/repositories/repository_providers.dart';
import 'package:courtify/presentation/features/auth/providers/auth_provider.dart';
import 'package:courtify/domain/usecases/make_booking_usecase.dart';

final makeBookingUseCaseProvider = Provider<MakeBookingUseCase>((ref) {
  return MakeBookingUseCase(ref.watch(bookingRepositoryProvider));
});

// Provider for Customer Bookings
final customerBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.userId == null) return [];
  
  return await repository.getCustomerBookings(authState.userId!);
});

// Provider for Owner Bookings
final ownerBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return await repository.getAllBookings();
});

// Modern Riverpod Notifier for managing booking actions (Cancel, Confirm, etc.)
class BookingActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> cancelBooking(int bookingId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(bookingRepositoryProvider);
      await repository.updateBookingStatus(bookingId, BookingStatus.cancelled);
      ref.invalidate(customerBookingsProvider);
      ref.invalidate(ownerBookingsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createBooking({
    required int userId,
    required int courtId,
    required int slotId,
    required DateTime bookDate,
    required String startTime,
    required String endTime,
    required double totalPrice,
  }) async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(makeBookingUseCaseProvider);
      await useCase.execute(
        userId: userId,
        courtId: courtId,
        slotId: slotId,
        bookDate: bookDate,
        startTime: startTime,
        endTime: endTime,
        totalPrice: totalPrice,
        currentTime: DateTime.now(),
      );
      ref.invalidate(customerBookingsProvider);
      ref.invalidate(ownerBookingsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(int bookingId, BookingStatus status) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(bookingRepositoryProvider);
      await repository.updateBookingStatus(bookingId, status);
      ref.invalidate(customerBookingsProvider);
      ref.invalidate(ownerBookingsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final bookingActionProvider = NotifierProvider<BookingActionNotifier, AsyncValue<void>>(
  BookingActionNotifier.new,
);
