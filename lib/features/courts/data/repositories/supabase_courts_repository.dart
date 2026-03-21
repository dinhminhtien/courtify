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
          .select('id, court_number, created_at')
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

      // 1. Lazy Release: Clean up dangling 'HOLD' slots
      // Finds slots that are 'HOLD' but no longer have an active/valid PENDING booking
      try {
        final now = DateTime.now().toUtc().toIso8601String();
        
        // Find all HOLD slots for this court and date
        final holdSlots = await _client
            .from('court_slots')
            .select('id')
            .eq('court_id', courtId)
            .eq('slot_date', dateStr)
            .eq('status', 'HOLD');

        if ((holdSlots as List).isNotEmpty) {
           final holdSlotIds = holdSlots.map((s) => s['id'] as String).toList();
           
           // Check which of these actually have a VALID (non-expired) PENDING booking
           final validBookings = await _client
               .from('bookings')
               .select('slot_id')
               .eq('status', 'PENDING')
               .inFilter('slot_id', holdSlotIds)
               .gt('hold_expires_at', now);
           
           final validSlotIds = (validBookings as List).map((b) => b['slot_id'] as String).toSet();
           
           // Any slot that is 'HOLD' but NOT in validSlotIds should be released
           final slotsToRelease = holdSlotIds.where((id) => !validSlotIds.contains(id)).toList();
           
           if (slotsToRelease.isNotEmpty) {
              await _client.from('court_slots').update({'status': 'AVAILABLE'}).inFilter('id', slotsToRelease);
              
              // Also ensures any expired PENDING bookings for these slots are marked CANCELLED
              await _client.from('bookings').update({'status': 'CANCELLED'})
                  .inFilter('slot_id', slotsToRelease)
                  .eq('status', 'PENDING')
                  .lt('hold_expires_at', now);
                  
              debugPrint('Auto-released ${slotsToRelease.length} dangling/expired slots');
           }
        }
      } catch (e) {
        debugPrint('Lazy release error (ignored): $e');
      }

      // 2. Fetch slots
      final data = await _client
          .from('court_slots')
          .select('id, court_id, slot_date, start_time, end_time, price, status, created_at')
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

    List<CourtSlotEntity> currentSlots = [];
    
    // We don't do an initial fetch here anymore to avoid redundant calls.
    // The Notifier will call getSlotsForCourtAndDate separately.

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
  callback: (payload) {
    // If the Notifier is active, it will call loadSlots once.
    // This callback handles subsequent incremental changes.
    // For simplicity, especially since currentSlots is local to this method, 
    // it's actually better to just signal the Notifier that a change happened 
    // but the Notifier already receives the UPDATED list or handles 
    // the incremental update.
    
    // Wait, if I want to avoid re-fetching, 
    // I MUST pass the change back to the notifier.
    // The current signature is onUpdate(List<CourtSlotEntity>).
    // Let's modify the repository to be slightly more generic if needed, 
    // but for now I'll just keep the incremental update logic in a way 
    // that it can be passed back safely.
    
    // Actually, I'll let the Notifier handle the current state.
    // I'll change the onUpdate signature or just allow it to re-fetch 
    // IF we can't maintain state here.
    
    // But re-fetching is exactly what we want to avoid.
    // Let's keep the logic but we need access to the "latest" list.
    // I'll re-add the initial state sync or have the Notifier pass the current list.
    
    // Better: Notifier calls a method that returns a Stream of lists.
    // For now, I'll use a hack where the repository re-fetches only once 
    // then handles subsequent changes if currentSlots is populated.
    
    if (currentSlots.isEmpty) {
      getSlotsForCourtAndDate(courtId: courtId, date: date).then((slots) {
        currentSlots = slots;
        onUpdate(slots);
      });
      return;
    }

    final newMap = payload.newRecord;
    final oldMap = payload.oldRecord;
    
    if (payload.eventType == PostgresChangeEvent.update && newMap.isNotEmpty) {
      final newSlot = CourtSlotModel.fromJson(newMap);
      final newSlotDate = newSlot.slotDate.toIso8601String().split('T')[0];
      final exists = currentSlots.any((s) => s.id == newSlot.id);
      if (newSlotDate == dateStr) {
        if (exists) {
          currentSlots = currentSlots.map((s) => s.id == newSlot.id ? newSlot : s).toList();
        } else {
          currentSlots = [...currentSlots, newSlot]..sort((a,b) => a.startTime.compareTo(b.startTime));
        }
        onUpdate(currentSlots);
      } else if (exists) {
        // Slot moved FROM today TO another date, remove it
        currentSlots = currentSlots.where((s) => s.id != newSlot.id).toList();
        onUpdate(currentSlots);
      }
    } else if (payload.eventType == PostgresChangeEvent.insert && newMap.isNotEmpty) {
       final newSlot = CourtSlotModel.fromJson(newMap);
       final newSlotDate = newSlot.slotDate.toIso8601String().split('T')[0];
       if (newSlotDate == dateStr) {
         currentSlots = [...currentSlots, newSlot]..sort((a,b) => a.startTime.compareTo(b.startTime));
         onUpdate(currentSlots);
       }
    } else if (payload.eventType == PostgresChangeEvent.delete && oldMap.isNotEmpty) {
       final oldId = oldMap['id'];
       currentSlots = currentSlots.where((s) => s.id != oldId).toList();
       onUpdate(currentSlots);
    }
  },
        )
        .subscribe();
  }

  @override
  Future<CourtEntity> addCourt({required int courtNumber}) async {
    try {
      final data = await _client
          .from('courts')
          .insert({'court_number': courtNumber})
          .select()
          .single();
      return CourtModel.fromJson(data);
    } catch (e) {
      debugPrint('Add court error: $e');
      rethrow;
    }
  }
}
