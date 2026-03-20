import 'package:flutter_test/flutter_test.dart';
import 'package:courtify/core/utils/booking_utils.dart';

void main() {
  group('Booking Logic Tests', () {
    test('total price calculation with multiple slots', () {
      final prices = [10000, 20000, 15000];
      final result = calculateTotal(prices);
      expect(result, 45000);
    });

    test('total price calculation with empty list', () {
      final prices = <int>[];
      final result = calculateTotal(prices);
      expect(result, 0);
    });
  });
}
