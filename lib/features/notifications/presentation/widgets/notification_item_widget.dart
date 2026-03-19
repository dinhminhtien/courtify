import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationItemWidget extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : AppTheme.primaryContainer.withValues(alpha: 0.5),

          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.5),
              width: 1,
            ),

          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: notification.isRead ? theme.colorScheme.onSurface : AppTheme.primary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(notification.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'booking_confirmed':
        iconData = Icons.event_available_rounded;
        iconColor = AppTheme.success;
        break;
      case 'payment_success':
        iconData = Icons.check_circle_rounded;
        iconColor = AppTheme.success;
        break;
      case 'reminder':
        iconData = Icons.notifications_active_rounded;
        iconColor = AppTheme.info;
        break;
      default:
        iconData = Icons.notifications_rounded;
        iconColor = AppTheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),

      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }
  }
}
