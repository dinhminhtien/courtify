import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
}

class SupabaseNotificationRemoteDataSource implements NotificationRemoteDataSource {
  final SupabaseClient _supabaseClient;

  SupabaseNotificationRemoteDataSource(this._supabaseClient);

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final response = await _supabaseClient
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => NotificationModel.fromJson(json)).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _supabaseClient
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _supabaseClient
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }
}
