import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:courtify/data/models/court_model.dart';
import 'package:courtify/data/models/slot_model.dart';

abstract class ICourtRemoteDataSource {
  Future<List<CourtModel>> getAllCourts();
  Future<List<SlotModel>> getSlotsByCourt(int courtId, String date);
  Future<List<SlotModel>> getSlotsByDate(String date);
}

class CourtRemoteDataSource implements ICourtRemoteDataSource {
  final SupabaseClient client;

  CourtRemoteDataSource(this.client);

  @override
  Future<List<CourtModel>> getAllCourts() async {
    final response = await client
        .from('badminton_court')
        .select()
        .eq('status_court', 'AVAILABLE');
    
    return (response as List).map((json) => CourtModel.fromJson(json)).toList();
  }

  @override
  Future<List<SlotModel>> getSlotsByCourt(int courtId, String date) async {
    final response = await client
        .from('slot')
        .select('*, badminton_court(*), price_type(*)')
        .eq('badminton_court_id', courtId)
        .eq('date', date)
        .order('time_start');
    
    return (response as List).map((json) => SlotModel.fromJson(json)).toList();
  }

  @override
  Future<List<SlotModel>> getSlotsByDate(String date) async {
    final response = await client
        .from('slot')
        .select('*, badminton_court(*), price_type(*)')
        .eq('date', date)
        .order('time_start');
    
    return (response as List).map((json) => SlotModel.fromJson(json)).toList();
  }
}
