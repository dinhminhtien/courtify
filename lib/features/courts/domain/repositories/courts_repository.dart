import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/court.dart';
import '../entities/court_slot.dart';

abstract class CourtsRepository {
  Future<List<CourtEntity>> getCourts();

  Future<List<CourtSlotEntity>> getSlotsForCourtAndDate({
    required String courtId,
    required DateTime date,
  });

  RealtimeChannel subscribeToSlots({
    required String courtId,
    required DateTime date,
    required void Function(List<CourtSlotEntity>) onUpdate,
  });

  Future<CourtEntity> addCourt({required int courtNumber});
  Future<void> updateSlotsStatus({required List<String> slotIds, required String status});
}

