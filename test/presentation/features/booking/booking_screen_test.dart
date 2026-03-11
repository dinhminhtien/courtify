import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dummy implementation of screen
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Court')),
      body: Center(
        child: ElevatedButton(
          key: const Key('book_now_button'),
          onPressed: () {
            // Handle booking logic
          },
          child: const Text('Book Now'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Booking Flow UI test - finding Book Now button', (WidgetTester tester) async {
    // Arrange: Build our app in a ProviderScope (for Riverpod) and MaterialApp
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BookingScreen(),
        ),
      ),
    );

    // Assert: Verify that our button is present
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Book Now'), findsOneWidget);

    // Act: Tap the button
    await tester.tap(find.byKey(const Key('book_now_button')));
    await tester.pump(); // Trigger frame rebuild 

    // Additional assertions can be placed here to check if state changed / navigation happened
  });
}
