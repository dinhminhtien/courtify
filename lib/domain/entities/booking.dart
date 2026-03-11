import 'slot.dart';

enum BookingStatus { pending, confirmed, completed, cancelled }
enum PaymentStatus { unpaid, paid }

class Booking {
  final int id;
  final int userId;
  final int? paymentMethodId;
  final double totalPrice;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? cancelReason;
  final DateTime createdAt;
  final String? userName;
  final List<Slot> slots;

  Booking({
    required this.id,
    required this.userId,
    this.userName,
    this.paymentMethodId,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    this.cancelReason,
    required this.createdAt,
    this.slots = const [],
  });

  /// Current logic based on the first slot's date and time
  bool canCancel(DateTime currentTime, {int hoursThreshold = 2}) {
    if (status == BookingStatus.completed || status == BookingStatus.cancelled) {
      return false;
    }
    
    if (slots.isEmpty) return true; // Or handle as needed

    if (status == BookingStatus.pending || status == BookingStatus.confirmed) {
      final firstSlot = slots.first;
      final timeParts = firstSlot.startTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final playDateTime = DateTime(
        firstSlot.date.year,
        firstSlot.date.month,
        firstSlot.date.day,
        hour,
        minute,
      );

      final difference = playDateTime.difference(currentTime);
      return difference.inHours >= hoursThreshold;
    }

    return false;
  }

  bool canBeMarkedCompleted(DateTime currentTime, bool hasCheckedIn) {
    if (status == BookingStatus.cancelled) return false;
    if (slots.isEmpty) return false;

    final firstSlot = slots.first;
    final timeParts = firstSlot.startTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final playDateTime = DateTime(
      firstSlot.date.year,
      firstSlot.date.month,
      firstSlot.date.day,
      hour,
      minute,
    );

    return (currentTime.isAfter(playDateTime) || currentTime.isAtSameMomentAs(playDateTime)) 
           && hasCheckedIn;
  }
}
