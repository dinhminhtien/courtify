import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:courtify/data/models/booking_model.dart';

abstract class IBookingRemoteDataSource {
  Future<List<BookingModel>> getBookingsByCustomer(int userId);
  Future<List<BookingModel>> getAllBookings();
  Future<BookingModel> createBooking(BookingModel booking, int slotId);
  Future<void> updateBookingStatus(int id, String status);
  Future<bool> checkOverlap(int courtId, String date, String startTime, String endTime);
}

class BookingRemoteDataSource implements IBookingRemoteDataSource {
  final SupabaseClient client;

  BookingRemoteDataSource(this.client);

  @override
  Future<List<BookingModel>> getBookingsByCustomer(int userId) async {
    final response = await client
        .from('booking')
        .select('*, users(*), booking_detail(*, slot(*, badminton_court(*)))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => BookingModel.fromJson(json)).toList();
  }

  @override
  Future<List<BookingModel>> getAllBookings() async {
    final response = await client
        .from('booking')
        .select('*, users(*), booking_detail(*, slot(*, badminton_court(*)))')
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => BookingModel.fromJson(json)).toList();
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking, int slotId) async {
    // 1. Insert Booking
    final bookingResponse = await client
        .from('booking')
        .insert(booking.toJson())
        .select()
        .single();
    
    final newBookingId = bookingResponse['booking_id'] as int;

    // 2. Insert Booking Detail
    await client.from('booking_detail').insert({
      'booking_id': newBookingId,
      'slot_id': slotId,
      'price': booking.totalPrice, // Simplified for now
    });

    // 3. Lock Slot
    await client.from('slot').update({'is_locked': true}).eq('slot_id', slotId);

    // 4. Return full object
    final fullResponse = await client
        .from('booking')
        .select('*, booking_detail(*, slot(*, badminton_court(*)))')
        .eq('booking_id', newBookingId)
        .single();
    
    return BookingModel.fromJson(fullResponse);
  }

  @override
  Future<void> updateBookingStatus(int id, String status) async {
    await client
        .from('booking')
        .update({'booking_status': status.toUpperCase()})
        .eq('booking_id', id);
  }

  @override
  Future<bool> checkOverlap(int courtId, String date, String startTime, String endTime) async {
    final response = await client
        .from('slot')
        .select()
        .eq('badminton_court_id', courtId)
        .eq('date', date)
        .eq('is_locked', true)
        .or('and(time_start.lt.$endTime,time_end.gt.$startTime)');
    
    return (response as List).isNotEmpty;
  }
}
