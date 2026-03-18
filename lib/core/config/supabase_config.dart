import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined in the .env file.',
      );
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  SupabaseClient get client => Supabase.instance.client;
}

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────

class CourtifyUser {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String role; // 'customer' | 'owner'
  final DateTime? createdAt;

  CourtifyUser({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    this.role = 'customer',
    this.createdAt,
  });

  factory CourtifyUser.fromJson(Map<String, dynamic> json) => CourtifyUser(
    id: json['id'] as String,
    email: json['email'] as String?,
    fullName: json['full_name'] as String?,
    phone: json['phone'] as String?,
    role: json['role'] as String? ?? 'customer',
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'phone': phone,
    'role': role,
  };

  bool get isOwner => role == 'owner';
}

class Court {
  final String id;
  final int courtNumber;
  final DateTime? createdAt;

  Court({required this.id, required this.courtNumber, this.createdAt});

  factory Court.fromJson(Map<String, dynamic> json) => Court(
    id: json['id'] as String,
    courtNumber: json['court_number'] as int,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );

  String get label => 'Sân $courtNumber';
}

class CourtSlot {
  final String id;
  final String courtId;
  final DateTime slotDate;
  final String startTime;
  final String endTime;
  final int price;
  final String status; // AVAILABLE | BOOKED | HOLD | BLOCKED
  final DateTime? createdAt;

  CourtSlot({
    required this.id,
    required this.courtId,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.price,
    this.status = 'AVAILABLE',
    this.createdAt,
  });

  factory CourtSlot.fromJson(Map<String, dynamic> json) => CourtSlot(
    id: json['id'] as String,
    courtId: json['court_id'] as String,
    slotDate: DateTime.parse(json['slot_date'] as String),
    startTime: json['start_time'] as String,
    endTime: json['end_time'] as String,
    price: json['price'] as int,
    status: json['status'] as String? ?? 'AVAILABLE',
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'startTime': startTime.length >= 5 ? startTime.substring(0, 5) : startTime,
    'endTime': endTime.length >= 5 ? endTime.substring(0, 5) : endTime,
    'price': price,
    'status': status,
    'date': slotDate,
    'courtId': courtId,
  };
}

class Booking {
  final String id;
  final String userId;
  final String courtId;
  final String slotId;
  final String status; // PENDING | CONFIRMED | COMPLETED | CANCELLED
  final String paymentStatus; // UNPAID | PAID
  final DateTime? holdExpiresAt;
  final DateTime? createdAt;
  final int? orderCode;
  // Joined fields
  final CourtSlot? slot;
  final Court? court;

  Booking({
    required this.id,
    required this.userId,
    required this.courtId,
    required this.slotId,
    this.status = 'PENDING',
    this.paymentStatus = 'UNPAID',
    this.holdExpiresAt,
    this.createdAt,
    this.orderCode,
    this.slot,
    this.court,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    courtId: json['court_id'] as String,
    slotId: json['slot_id'] as String,
    status: json['status'] as String? ?? 'PENDING',
    paymentStatus: json['payment_status'] as String? ?? 'UNPAID',
    holdExpiresAt: json['hold_expires_at'] != null
        ? DateTime.parse(json['hold_expires_at'] as String)
        : null,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
    orderCode: json['order_code'] as int?,
    slot: json['court_slots'] != null
        ? CourtSlot.fromJson(json['court_slots'] as Map<String, dynamic>)
        : null,
    court: json['courts'] != null
        ? Court.fromJson(json['courts'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toDisplayMap() {
    final slotDate = slot?.slotDate ?? DateTime.now();
    return {
      'id': id,
      'courtNumber': court?.courtNumber ?? 0,
      'courtLabel': court?.label ?? 'Sân',
      'dateFormatted':
          '${slotDate.day.toString().padLeft(2, '0')}/${slotDate.month.toString().padLeft(2, '0')}/${slotDate.year}',
      'date':
          '${slotDate.day.toString().padLeft(2, '0')}/${slotDate.month.toString().padLeft(2, '0')}/${slotDate.year}',
      'startTime': slot?.startTime != null && slot!.startTime.length >= 5 ? slot!.startTime.substring(0, 5) : (slot?.startTime ?? ''),
      'endTime': slot?.endTime != null && slot!.endTime.length >= 5 ? slot!.endTime.substring(0, 5) : (slot?.endTime ?? ''),
      'price': slot?.price ?? 0,
      'status': status,
      'paymentStatus': paymentStatus,
      'isUpcoming': holdExpiresAt != null
          ? holdExpiresAt!.isAfter(DateTime.now())
          : (status == 'PENDING' || status == 'CONFIRMED'),
    };
  }
}

class Payment {
  final String id;
  final String bookingId;
  final int amount;
  final String? transactionId;
  final String status;
  final DateTime? createdAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    this.transactionId,
    this.status = 'UNPAID',
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as String,
    bookingId: json['booking_id'] as String,
    amount: json['amount'] as int,
    transactionId: json['transaction_id'] as String?,
    status: json['status'] as String? ?? 'UNPAID',
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );
}

// ─────────────────────────────────────────────
// Auth Service
// ─────────────────────────────────────────────

class AuthService {
  final SupabaseClient _client = SupabaseService.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone, 'role': 'customer'},
    );
  }

  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'https://courtify-fbpxu80.public.builtwithrocket.new',
        );
        return true;
      } else {
        // Native Google Sign-In
        const webClientId = String.fromEnvironment(
          'GOOGLE_WEB_CLIENT_ID',
          defaultValue: '',
        );
        if (webClientId.isEmpty) return false;

        // For native, use signInWithOAuth with deep link
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.courtify://login-callback',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<CourtifyUser?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data == null) return null;
      return CourtifyUser.fromJson(data);
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }
}

// ─────────────────────────────────────────────
// Courts Service
// ─────────────────────────────────────────────

class CourtsService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<List<Court>> getCourts() async {
    try {
      final data = await _client
          .from('courts')
          .select()
          .order('court_number', ascending: true);
      return (data as List).map((e) => Court.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Get courts error: $e');
      return [];
    }
  }

  Future<List<CourtSlot>> getSlotsForCourtAndDate({
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
      return (data as List).map((e) => CourtSlot.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Get slots error: $e');
      return [];
    }
  }

  RealtimeChannel subscribeToSlots({
    required String courtId,
    required DateTime date,
    required void Function(List<CourtSlot>) onUpdate,
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

// ─────────────────────────────────────────────
// Bookings Service
// ─────────────────────────────────────────────

class BookingsService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<Booking?> createBooking({
    required List<String> slotIds,
    required String courtId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Set slots to HOLD - Use loop if inFilter has issues
      debugPrint('Setting slots to HOLD: $slotIds');
      for (final id in slotIds) {
        final res = await _client
            .from('court_slots')
            .update({'status': 'HOLD'})
            .eq('id', id)
            .select();
        debugPrint('Slot $id HOLD result: $res');
      }

      final holdExpiresAt = DateTime.now()
          .add(const Duration(minutes: 5))
          .toUtc()
          .toIso8601String();

      // Generate a shared order code for this group of slots
      final orderCode = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final List<Map<String, dynamic>> bookingsToInsert = slotIds.map((id) => {
        'user_id': userId,
        'court_id': courtId,
        'slot_id': id,
        'status': 'PENDING',
        'payment_status': 'UNPAID',
        'hold_expires_at': holdExpiresAt,
        'order_code': orderCode,
      }).toList();

      final data = await _client
          .from('bookings')
          .insert(bookingsToInsert)
          .select('*, court_slots(*), courts(*)')
          .order('id', ascending: true);

      if ((data as List).isEmpty) return null;
      return Booking.fromJson(data.first);
    } catch (e) {
      debugPrint('Create booking error: $e');
      // Release holds on error
      try {
        for (final id in slotIds) {
          await _client
              .from('court_slots')
              .update({'status': 'AVAILABLE'})
              .eq('id', id);
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<List<Booking>> getUserBookings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await _client
          .from('bookings')
          .select('*, court_slots(*), courts(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => Booking.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Get user bookings error: $e');
      return [];
    }
  }

  Future<List<Booking>> getAllBookings() async {
    try {
      final data = await _client
          .from('bookings')
          .select('*, court_slots(*), courts(*), users(*)')
          .order('created_at', ascending: false);
      return (data as List).map((e) => Booking.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Get all bookings error: $e');
      return [];
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      // Get booking to find grouping info
      final booking = await _client
          .from('bookings')
          .select('slot_id, user_id, court_id, hold_expires_at')
          .eq('id', bookingId)
          .single();

      final userId = booking['user_id'];
      final courtId = booking['court_id'];
      final holdExpiresAt = booking['hold_expires_at'];

      if (holdExpiresAt != null) {
        // Find all bookings in same group
        final relatedBookings = await _client
            .from('bookings')
            .select('slot_id')
            .eq('user_id', userId)
            .eq('court_id', courtId)
            .eq('hold_expires_at', holdExpiresAt);

        final slotIds = (relatedBookings as List)
            .map((b) => b['slot_id'] as String)
            .toList();

        await _client
            .from('bookings')
            .update({'status': 'CANCELLED'})
            .eq('user_id', userId)
            .eq('court_id', courtId)
            .eq('hold_expires_at', holdExpiresAt);

        // Release all slots
        for (final id in slotIds) {
          await _client
              .from('court_slots')
              .update({'status': 'AVAILABLE'})
              .eq('id', id);
        }
      } else {
        // Fallback for single booking without order_code
        await _client
            .from('bookings')
            .update({'status': 'CANCELLED'})
            .eq('id', bookingId);

        await _client
            .from('court_slots')
            .update({'status': 'AVAILABLE'})
            .eq('id', booking['slot_id']);
      }
    } catch (e) {
      debugPrint('Cancel booking error: $e');
      rethrow;
    }
  }

  Future<void> confirmBooking(String bookingId) async {
    try {
      await _client
          .from('bookings')
          .update({'status': 'CONFIRMED'})
          .eq('id', bookingId);
    } catch (e) {
      debugPrint('Confirm booking error: $e');
      rethrow;
    }
  }

  Future<void> completeBooking(String bookingId) async {
    try {
      await _client
          .from('bookings')
          .update({'status': 'COMPLETED'})
          .eq('id', bookingId);
    } catch (e) {
      debugPrint('Complete booking error: $e');
      rethrow;
    }
  }
}

// ─────────────────────────────────────────────
// Payments Service
// ─────────────────────────────────────────────

class PaymentsService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<Payment?> createPayment({
    required String bookingId,
    required int amount,
    String? transactionId,
  }) async {
    try {
      final data = await _client
          .from('payments')
          .insert({
            'booking_id': bookingId,
            'amount': amount,
            'transaction_id': transactionId,
            'status': 'UNPAID',
          })
          .select()
          .single();
      return Payment.fromJson(data);
    } catch (e) {
      debugPrint('Create payment error: $e');
      return null;
    }
  }

  Future<Payment?> createCashPayment({
    required String bookingId,
    List<String>? slotIds,
  }) async {
    try {
      List<String> finalSlotIds = slotIds ?? [];
      String? userId;
      String? courtId;
      String? rawHoldExpiresAt;
      int totalAmount = 0;

      if (finalSlotIds.isEmpty) {
        // Fallback to grouping logic if not provided
        final bookingData = await _client
            .from('bookings')
            .select('slot_id, user_id, court_id, hold_expires_at')
            .eq('id', bookingId)
            .single();

        userId = bookingData['user_id'];
        courtId = bookingData['court_id'];
        rawHoldExpiresAt = bookingData['hold_expires_at'];

        if (rawHoldExpiresAt != null) {
          final groupBookings = await _client
              .from('bookings')
              .select('slot_id')
              .eq('user_id', userId as Object)
              .eq('court_id', courtId as Object)
              .eq('hold_expires_at', rawHoldExpiresAt as Object);
          finalSlotIds = (groupBookings as List).map((b) => b['slot_id'] as String).toList();
        } else {
          finalSlotIds = [bookingData['slot_id'] as String];
        }
      } else {
        // Even if slotIds provided, we need grouping info to update all bookings' status
        final bookingData = await _client
            .from('bookings')
            .select('user_id, court_id, hold_expires_at')
            .eq('id', bookingId)
            .single();
        userId = bookingData['user_id'];
        courtId = bookingData['court_id'];
        rawHoldExpiresAt = bookingData['hold_expires_at'];
      }

      final slotsData = await _client
          .from('court_slots')
          .select('price')
          .inFilter('id', finalSlotIds);

      totalAmount = (slotsData as List).fold(0, (sum, s) => sum + (s['price'] as int));

      // Create payment record with CASH method and PENDING_CASH status
      final data = await _client
          .from('payments')
          .insert({
            'booking_id': bookingId,
            'amount': totalAmount,
            'transaction_id': 'CASH-${DateTime.now().millisecondsSinceEpoch}',
            'status': 'PENDING_CASH',
          })
          .select()
          .single();

      // Confirm bookings immediately for cash payment
      if (rawHoldExpiresAt != null && userId != null && courtId != null) {
        await _client
            .from('bookings')
            .update({'payment_status': 'PENDING_CASH', 'status': 'CONFIRMED'})
            .eq('user_id', userId as Object)
            .eq('court_id', courtId as Object)
            .eq('hold_expires_at', rawHoldExpiresAt as Object);
      } else {
        await _client
            .from('bookings')
            .update({'payment_status': 'PENDING_CASH', 'status': 'CONFIRMED'})
            .eq('id', bookingId);
      }

      // Update slots to BOOKED
      debugPrint('Updating slots to BOOKED: $finalSlotIds');
      for (final id in finalSlotIds) {
        await _client
            .from('court_slots')
            .update({'status': 'BOOKED'})
            .eq('id', id);
      }

      return Payment.fromJson(data);
    } catch (e) {
      debugPrint('Create cash payment error: $e');
      rethrow;
    }
  }

  Future<Payment?> confirmPayment({
    required String bookingId,
    required String transactionId,
    List<String>? slotIds,
  }) async {
    try {
      // Update payment status
      await _client
          .from('payments')
          .update({'status': 'PAID', 'transaction_id': transactionId})
          .eq('booking_id', bookingId);

      List<String> finalSlotIds = slotIds ?? [];
      
      String? userId;
      String? courtId;
      String? rawHoldExpiresAt;

      if (finalSlotIds.isEmpty) {
        // Fallback to grouping logic if not provided
        final booking = await _client
            .from('bookings')
            .select('slot_id, user_id, court_id, hold_expires_at')
            .eq('id', bookingId)
            .single();
        
        userId = booking['user_id'];
        courtId = booking['court_id'];
        rawHoldExpiresAt = booking['hold_expires_at'];

        if (rawHoldExpiresAt != null) {
          final groupBookings = await _client
              .from('bookings')
              .select('slot_id')
              .eq('user_id', userId as Object)
              .eq('court_id', courtId as Object)
              .eq('hold_expires_at', rawHoldExpiresAt as Object);
          finalSlotIds = (groupBookings as List).map((b) => b['slot_id'] as String).toList();
        } else {
          finalSlotIds = [booking['slot_id'] as String];
        }
      } else {
        // Even if slotIds provided, we need grouping info to update all bookings' status
        final bookingData = await _client
            .from('bookings')
            .select('user_id, court_id, hold_expires_at')
            .eq('id', bookingId)
            .single();
        userId = bookingData['user_id'];
        courtId = bookingData['court_id'];
        rawHoldExpiresAt = bookingData['hold_expires_at'];
      }

      // Update booking payment status and confirm
      if (rawHoldExpiresAt != null && userId != null && courtId != null) {
        await _client
            .from('bookings')
            .update({'payment_status': 'PAID', 'status': 'CONFIRMED'})
            .eq('user_id', userId as Object)
            .eq('court_id', courtId as Object)
            .eq('hold_expires_at', rawHoldExpiresAt as Object);
      } else {
        await _client
            .from('bookings')
            .update({'payment_status': 'PAID', 'status': 'CONFIRMED'})
            .eq('id', bookingId);
      }

      // Update slots to BOOKED
      debugPrint('Confirming slots to BOOKED: $finalSlotIds');
      for (final id in finalSlotIds) {
        await _client
            .from('court_slots')
            .update({'status': 'BOOKED'})
            .eq('id', id);
      }

      return null;
    } catch (e) {
      debugPrint('Confirm payment error: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getPaymentsForOwner() async {
    try {
      final data = await _client
          .from('payments')
          .select()
          .order('created_at', ascending: false);
      return (data as List).map((e) => Payment.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Get payments error: $e');
      return [];
    }
  }
}