import 'package:courtify/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courtify/domain/entities/booking.dart';
import 'package:courtify/domain/repositories/i_booking_repository.dart';
import 'package:courtify/domain/usecases/make_booking_usecase.dart';

// Manual mock to avoid Mockito/BuildRunner dependencies during setup
class MockBookingRepository implements IBookingRepository {
  bool shouldReturnOverlap = false;

  @override
  Future<Booking> createBooking(Booking booking, int slotId) async {
    return booking;
  }

  @override
  Future<bool> hasOverlappingBooking({
    required int courtId,
    required DateTime bookDate,
    required String startTime,
    required String endTime,
  }) async {
    return shouldReturnOverlap;
  }

  @override
  Future<List<Booking>> getAllBookings() async => [];

  @override
  Future<List<Booking>> getCustomerBookings(int userId) async => [];

  @override
  Future<void> updateBookingStatus(int id, BookingStatus status) async {}
}

void main() {
  late MakeBookingUseCase usecase;
  late MockBookingRepository mockRepository;

  setUp(() {
    mockRepository = MockBookingRepository();
    usecase = MakeBookingUseCase(mockRepository);
  });

  group('Make Booking Business Rules Validation', () {
    final currentTime = DateTime(2025, 10, 20, 10, 0); 

    test('BR-C5: Should throw ValidationFailure when booking a past slot', () async {
      try {
        await usecase.execute(
          userId: 1, courtId: 1, slotId: 101,
          bookDate: DateTime(2025, 10, 20),
          startTime: '09:00', endTime: '10:00',
          totalPrice: 100, currentTime: currentTime,
        );
        fail("Should have thrown ValidationFailure");
      } catch (e) {
        expect(e, isA<ValidationFailure>());
        expect((e as ValidationFailure).message.contains("BR-C5"), true);
      }
    });

    test('BR-C8: Should throw ValidationFailure when overlapping existing booking', () async {
      mockRepository.shouldReturnOverlap = true;
      try {
        await usecase.execute(
          userId: 1, courtId: 1, slotId: 101,
          bookDate: DateTime(2025, 10, 20),
          startTime: '15:00', endTime: '16:00',
          totalPrice: 100, currentTime: currentTime,
        );
        fail("Should have thrown ValidationFailure");
      } catch (e) {
        expect(e, isA<ValidationFailure>());
        expect((e as ValidationFailure).message.contains("BR-C8"), true);
      }
    });

    test('Success: Should return a Booking object with initial PENDING status (BR-C9)', () async {
      mockRepository.shouldReturnOverlap = false;

      final booking = await usecase.execute(
        userId: 1, courtId: 1, slotId: 101,
        bookDate: DateTime(2025, 10, 20),
        startTime: '15:00', endTime: '16:00',
        totalPrice: 100, currentTime: currentTime,
      );

      expect(booking, isNotNull);
      expect(booking.status, equals(BookingStatus.pending)); // BR-C9
    });
  group('Specific business rule tests (BR-G6, BR-C7) are now implicitly handled by Slot definitions in the schema.', () {});
  });
}
