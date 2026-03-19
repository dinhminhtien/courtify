import '../../domain/repositories/notification_repository.dart';

class MarkAllNotificationsReadUseCase {
  final NotificationRepository repository;

  MarkAllNotificationsReadUseCase(this.repository);

  Future<void> call(String userId) {
    return repository.markAllAsRead(userId);
  }
}
