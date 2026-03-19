import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_item_widget.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (notificationState.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: const Text('Đánh dấu tất cả là đã đọc'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
        color: AppTheme.primary,
        child: _buildBody(notificationState, ref),
      ),
    );
  }

  Widget _buildBody(NotificationState state, WidgetRef ref) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
            const SizedBox(height: 16),
            Text('Đã có lỗi xảy ra: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(notificationProvider.notifier).fetchNotifications(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, color: AppTheme.muted.withValues(alpha: 0.5), size: 80),
            const SizedBox(height: 16),

            Text(
              'Bạn chưa có thông báo nào',
              style: TextStyle(color: AppTheme.muted, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.notifications.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return NotificationItemWidget(
          notification: notification,
          onTap: () async {
            if (!notification.isRead) {
              await ref.read(notificationProvider.notifier).markAsRead(notification.id);
            }
            // Navigate or show details if needed
          },
        );
      },
    );
  }
}
