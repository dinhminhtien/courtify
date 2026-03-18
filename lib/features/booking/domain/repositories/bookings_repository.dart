import '../entities/booking.dart';

abstract class BookingsRepository {
  Future<BookingEntity?> createBooking({
    required List<String> slotIds,
    required String courtId,
  });

  Future<List<BookingEntity>> getUserBookings();

  Future<List<BookingEntity>> getAllBookings();

  Future<void> cancelBooking(String bookingId);

  Future<void> confirmBooking(String bookingId);

  Future<void> completeBooking(String bookingId);
}
