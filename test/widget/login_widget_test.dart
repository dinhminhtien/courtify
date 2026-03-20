import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courtify/features/auth/presentation/sign_up_login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // Initialize Supabase with dummy values for testing
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      anonKey: 'placeholder-key',
    );
  });

  testWidgets('SignUpLoginScreen renders and has login button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        child: Sizer(
          builder: (context, orientation, deviceType) {
            return const MaterialApp(
              home: SignUpLoginScreen(),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify if 'Đăng nhập' button exists
    expect(find.text('Đăng nhập'), findsWidgets);
    
    // Find text fields
    final emailField = find.byType(TextField).first;
    expect(emailField, findsOneWidget);

    // Enter text
    await tester.enterText(emailField, 'test@courtify.vn');
    expect(find.text('test@courtify.vn'), findsOneWidget);
  });
}
