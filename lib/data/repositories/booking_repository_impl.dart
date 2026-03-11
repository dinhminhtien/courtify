import 'package:courtify/domain/entities/booking.dart';
import 'package:courtify/domain/repositories/i_booking_repository.dart';
import 'package:courtify/data/datasources/remote/booking_remote_data_source.dart';
import 'package:courtify/data/models/booking_model.dart';

class BookingRepositoryImpl implements IBookingRepository {
  final IBookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl(this.remoteDataSource);

  @override
  Future<Booking> createBooking(Booking booking, int slotId) async {
    final model = BookingModel(
      id: booking.id,
      userId: booking.userId,
      paymentMethodId: booking.paymentMethodId,
      totalPrice: booking.totalPrice,
      status: booking.status,
      paymentStatus: booking.paymentStatus,
      cancelReason: booking.cancelReason,
      createdAt: booking.createdAt,
      slots: booking.slots,
    );
    return await remoteDataSource.createBooking(model, slotId);
  }

  @override
  Future<bool> hasOverlappingBooking({
    required int courtId,
    required DateTime bookDate,
    required String startTime,
    required String endTime,
  }) async {
    return await remoteDataSource.checkOverlap(
      courtId,
      bookDate.toIso8601String().split('T')[0],
      startTime,
      endTime,
    );
  }

  @override
  Future<List<Booking>> getCustomerBookings(int userId) async {
    return await remoteDataSource.getBookingsByCustomer(userId);
  }

  @override
  Future<List<Booking>> getAllBookings() async {
    return await remoteDataSource.getAllBookings();
  }

  @override
  Future<void> updateBookingStatus(int id, BookingStatus status) async {
    await remoteDataSource.updateBookingStatus(id, status.name);
  }
}
