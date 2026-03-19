import '../../domain/repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationRepository repository;

  MarkNotificationReadUseCase(this.repository);

  Future<void> call(String notificationId) {
    return repository.markAsRead(notificationId);
  }
}
