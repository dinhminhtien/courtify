import 'package:flutter_test/flutter_test.dart';
import 'package:courtify/domain/entities/booking.dart';
import 'package:courtify/domain/entities/slot.dart';

void main() {
  group('Booking Entity Rules (BR-C10, BR-C11, BR-O6)', () {
    test('BR-C10: Should allow cancel when status is PENDING/CONFIRMED and strictly >= 2 hours before play time', () {
      final bookDate = DateTime(2025, 10, 20); 
      
      final booking = Booking(
        id: 1,
        userId: 1,
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.paid,
        totalPrice: 100.0,
        createdAt: DateTime.now(),
        slots: [
          Slot(
            id: 1,
            courtId: 1,
            priceTypeId: 1,
            date: bookDate,
            startTime: '15:00',
            endTime: '16:00',
            isLocked: true,
          ),
        ],
      );

      // Current time is 12:00 PM the same day (3 hours before play)
      final currentTime = DateTime(2025, 10, 20, 12, 0);
      final canCancel = booking.canCancel(currentTime);

      expect(canCancel, true);
    });

    test('BR-C10/C11: Should deny cancel when time is LESS than 2 hours before play time', () {
      final bookDate = DateTime(2025, 10, 20); 
      
      final booking = Booking(
        id: 1,
        userId: 1,
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.paid,
        totalPrice: 100.0,
        createdAt: DateTime.now(),
        slots: [
          Slot(
            id: 1,
            courtId: 1,
            priceTypeId: 1,
            date: bookDate,
            startTime: '15:00',
            endTime: '16:00',
            isLocked: true,
          ),
        ],
      );

      // Current time is 14:00 PM the same day (1 hour before play)
      final currentTime = DateTime(2025, 10, 20, 14, 0);
      final canCancel = booking.canCancel(currentTime);

      expect(canCancel, false);
    });

    test('BR-C11: Should deny cancel if booking status is already COMPLETED or CANCELLED', () {
      final booking = Booking(
        id: 1,
        userId: 1,
        status: BookingStatus.completed, 
        paymentStatus: PaymentStatus.paid,
        totalPrice: 100.0,
        createdAt: DateTime.now(),
        slots: [
          Slot(
            id: 1,
            courtId: 1,
            priceTypeId: 1,
            date: DateTime(2025, 10, 20),
            startTime: '15:00',
            endTime: '16:00',
            isLocked: true,
          ),
        ],
      );

      // Even if it's 3 hours before
      final currentTime = DateTime(2025, 10, 20, 12, 0);
      expect(booking.canCancel(currentTime), false);
    });

    test('BR-O6: Booking can be COMPLETED only if current time >= booking start time AND Customer has checked in', () {
      final booking = Booking(
        id: 1,
        userId: 1,
        status: BookingStatus.confirmed, 
        paymentStatus: PaymentStatus.paid,
        totalPrice: 100.0,
        createdAt: DateTime.now(),
        slots: [
          Slot(
            id: 1,
            courtId: 1,
            priceTypeId: 1,
            date: DateTime(2025, 10, 20),
            startTime: '15:00',
            endTime: '16:00',
            isLocked: true,
          ),
        ],
      );

      // Condition 1: Time < Start Time
      final beforeTime = DateTime(2025, 10, 20, 14, 0);
      expect(booking.canBeMarkedCompleted(beforeTime, true), false);

      // Condition 2: Time >= Start Time, NOT checked in
      final exactTime = DateTime(2025, 10, 20, 15, 0);
      expect(booking.canBeMarkedCompleted(exactTime, false), false);

      // Condition 3: Time >= Start Time, HAS checked in
      expect(booking.canBeMarkedCompleted(exactTime, true), true);

      // Condition 4: Time > Start Time, HAS checked in
      final afterTime = DateTime(2025, 10, 20, 15, 30);
      expect(booking.canBeMarkedCompleted(afterTime, true), true);
    });
  });
}
