// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Courtify';

  @override
  String get selectExperience => 'Select your experience';

  @override
  String get customer => 'Customer';

  @override
  String get customerSubtitle => 'Book courts & manage your schedule';

  @override
  String get owner => 'Owner';

  @override
  String get ownerSubtitle => 'Manage venue & customer slots';

  @override
  String get manageBookings => 'Manage Bookings';

  @override
  String get mySchedule => 'My Schedule';

  @override
  String get noBookingsFound => 'No Bookings Found';

  @override
  String get noBookingsYet => 'No bookings yet.';

  @override
  String get bookCourtToStart => 'Book a court slot to get started!';

  @override
  String get court => 'Court';

  @override
  String get total => 'Total';

  @override
  String get payment => 'Payment';

  @override
  String get totalPrice => 'Total Price';

  @override
  String get pending => 'PENDING';

  @override
  String get confirmed => 'CONFIRMED';

  @override
  String get completed => 'COMPLETED';

  @override
  String get cancelled => 'CANCELLED';

  @override
  String get paid => 'PAID';

  @override
  String get unpaid => 'UNPAID';

  @override
  String get markConfirmed => 'Mark Confirmed';

  @override
  String get markCompleted => 'Mark Completed';

  @override
  String get cancelBooking => 'Cancel Booking';

  @override
  String get noActionsAvailable => 'No actions available';

  @override
  String get cancelBookingDialogTitle => 'Cancel Booking?';

  @override
  String get cancelBookingDialogContent =>
      'Are you sure you want to cancel this booking? This action cannot be undone, and the slot will be released immediately.';

  @override
  String get keepIt => 'KEEP IT';

  @override
  String get cancel => 'CANCEL';

  @override
  String get payNow => 'PAY NOW';

  @override
  String get redirectingToPayment => 'Redirecting to VNPay / Momo...';

  @override
  String get bookingUpdated => 'Booking Updated';

  @override
  String get bookingCancelledSuccessfully => 'Booking Cancelled Successfully.';

  @override
  String get cannotCompleteError =>
      'Cannot complete: Time has not passed or Customer not checked in (BR-O6)';
}
