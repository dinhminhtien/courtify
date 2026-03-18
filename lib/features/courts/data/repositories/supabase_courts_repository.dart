import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/api/supabase_client.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_slot.dart';
import '../../domain/repositories/courts_repository.dart';
import '../models/court_model.dart';
import '../models/court_slot_model.dart';

class SupabaseCourtsRepository implements CourtsRepository {
  final SupabaseClient _client = SupabaseClientManager.instance.client;

  @override
  Future<List<CourtEntity>> getCourts() async {
    try {
      final data = await _client
          .from('courts')
          .select()
          .order('court_number', ascending: true);
      return (data as List).map((e) => CourtModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Get courts error: $e');
      return [];
    }
  }

  @override
  Future<List<CourtSlotEntity>> getSlotsForCourtAndDate({
    required String courtId,
    required DateTime date,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final data = await _client
          .from('court_slots')
          .select()
          .eq('court_id', courtId)
          .eq('slot_date', dateStr)
          .order('start_time', ascending: true);
      return (data as List).map((e) => CourtSlotModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Get slots error: $e');
      return [];
    }
  }

  @override
  RealtimeChannel subscribeToSlots({
    required String courtId,
    required DateTime date,
    required void Function(List<CourtSlotEntity>) onUpdate,
  }) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _client
        .channel('court_slots_${courtId}_$dateStr')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'court_slots',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'court_id',
            value: courtId,
          ),
          callback: (_) async {
            final updated = await getSlotsForCourtAndDate(
              courtId: courtId,
              date: date,
            );
            onUpdate(updated);
          },
        )
        .subscribe();
  }
}
