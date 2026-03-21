import 'package:flutter/material.dart';

import '../core/guards/route_guard.dart';
import '../features/booking/presentation/booking_confirmation_screen.dart';
import '../features/booking/presentation/booking_history_screen.dart';
import '../features/courts/presentation/home_screen.dart';
import '../features/owner/presentation/owner_dashboard_screen.dart';
import '../features/payment/presentation/payment_screen.dart';
import '../features/payment/presentation/payment_callback_screen.dart';
import '../features/auth/presentation/sign_up_login_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';

import '../features/courts/presentation/booking_screen.dart';



class AppRoutes {
  static const String initial = '/';
  static const String signUpLogin = '/sign-up-login-screen';
  static const String home = '/home-screen';
  static const String booking = '/booking-screen';
  static const String bookingConfirmation = '/booking-confirmation-screen';
  static const String bookingHistory = '/booking-history-screen';
  static const String payment = '/payment-screen';
  static const String ownerDashboard = '/owner-dashboard-screen';
  static const String profile = '/profile-screen';
  static const String notifications = '/notifications-screen';


  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const OnboardingScreen(),
    signUpLogin: (context) => RouteGuard(
      routeName: signUpLogin,
      child: const SignUpLoginScreen(),
    ),

    home: (context) => RouteGuard(
      routeName: home,
      child: const HomeScreen(),
    ),
    booking: (context) => RouteGuard(
      routeName: booking,
      child: const BookingScreen(),
    ),

    bookingConfirmation: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return RouteGuard(
        routeName: bookingConfirmation,
        child: BookingConfirmationScreen(bookingArgs: args),
      );
    },
    bookingHistory: (context) => RouteGuard(
      routeName: bookingHistory,
      child: const BookingHistoryScreen(),
    ),
    payment: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return RouteGuard(
        routeName: payment,
        child: PaymentScreen(paymentArgs: args),
      );
    },
    ownerDashboard: (context) => RouteGuard(
      routeName: ownerDashboard,
      child: const OwnerDashboardScreen(),
    ),
    profile: (context) => RouteGuard(
      routeName: profile,
      child: const ProfileScreen(),
    ),
    notifications: (context) => RouteGuard(
      routeName: notifications,
      child: const NotificationsScreen(),
    ),

  };

  static const String paymentSuccess = '/success';
  static const String paymentCancel = '/cancel';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (settings.name == null) {
      return _buildRoute(
        const Scaffold(body: Center(child: Text('Không tìm thấy trang'))),
      );
    }
    
    // Parse Uri to handle query parameters from PayOS redirects (like /success?orderCode=123)
    final uri = Uri.parse(settings.name!);
    
    if (uri.path == paymentSuccess || uri.path == paymentCancel) {
      return _buildRoute(
         RouteGuard(
           routeName: uri.path,
           child: PaymentCallbackScreen(queryParams: uri.queryParameters),
         )
      );
    }

    switch (settings.name) {
      case bookingConfirmation:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(BookingConfirmationScreen(bookingArgs: args));
      case payment:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(PaymentScreen(paymentArgs: args));
      default:
        return _buildRoute(
          const Scaffold(body: Center(child: Text('Không tìm thấy trang'))),
        );
    }
  }

  static PageRoute _buildRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}
