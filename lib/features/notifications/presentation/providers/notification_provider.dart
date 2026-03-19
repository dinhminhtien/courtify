import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/api/supabase_client.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─── Data Source & Repository Providers ─────────────────────────────────────

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return SupabaseNotificationRemoteDataSource(SupabaseClientManager.instance.client);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final remoteDataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remoteDataSource);
});

// ─── Use Case Providers ───────────────────────────────────────────────────

final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return GetNotificationsUseCase(repository);
});

final markNotificationReadUseCaseProvider = Provider<MarkNotificationReadUseCase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return MarkNotificationReadUseCase(repository);
});

final markAllNotificationsReadUseCaseProvider = Provider<MarkAllNotificationsReadUseCase>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return MarkAllNotificationsReadUseCase(repository);
});

// ─── State ─────────────────────────────────────────────────────────

class NotificationState {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

// ─── Notifier ─────────────────────────────────────────────────────────

class NotificationNotifier extends Notifier<NotificationState> {
  late final GetNotificationsUseCase _getNotificationsUseCase;
  late final MarkNotificationReadUseCase _markNotificationReadUseCase;
  late final MarkAllNotificationsReadUseCase _markAllNotificationsReadUseCase;
  RealtimeChannel? _realtimeChannel;

  @override

  NotificationState build() {
    _getNotificationsUseCase = ref.watch(getNotificationsUseCaseProvider);
    _markNotificationReadUseCase = ref.watch(markNotificationReadUseCaseProvider);
    _markAllNotificationsReadUseCase = ref.watch(markAllNotificationsReadUseCaseProvider);

    // Watch user changes
    ref.listen(currentUserProvider, (previous, next) {
      if (next != null) {
        fetchNotifications();
      } else {
        state = const NotificationState();
      }
    });

    // Load initial data if user is already present
    final user = ref.read(currentUserProvider);
    if (user != null) {
      Future.microtask(() {
        fetchNotifications();
        _setupRealtime(user.id);
      });
    }

    return const NotificationState();
  }

  void _setupRealtime(String userId) {
    _realtimeChannel?.unsubscribe();
    
    _realtimeChannel = SupabaseClientManager.instance.client
        .channel('public:notifications:user_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            fetchNotifications();
          },
        )
        .subscribe();
  }


  Future<void> fetchNotifications() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _getNotificationsUseCase(user.id);
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _markNotificationReadUseCase(notificationId);
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList(),
      );
    } catch (e) {
      // Log error but maintain state
    }
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _markAllNotificationsReadUseCase(user.id);
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
      );
    } catch (e) {
      // Log error
    }
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(() {
  return NotificationNotifier();
});
