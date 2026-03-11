import 'package:courtify/domain/entities/booking.dart';

abstract class IBookingRepository {
  /// Checks if there's any overlapping booking
  Future<bool> hasOverlappingBooking({
    required int courtId,
    required DateTime bookDate,
    required String startTime,
    required String endTime,
  });

  /// Saves the booking and returns the created Booking object
  Future<Booking> createBooking(Booking booking, int slotId);

  /// Fetches bookings for a specific user
  Future<List<Booking>> getCustomerBookings(int userId);

  /// Fetches all bookings (for Owner)
  Future<List<Booking>> getAllBookings();

  /// Updates the status of a booking
  Future<void> updateBookingStatus(int id, BookingStatus status);
}
