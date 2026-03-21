import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../domain/entities/court.dart';
import '../../domain/entities/court_slot.dart';
import '../../domain/repositories/courts_repository.dart';
import '../../data/repositories/supabase_courts_repository.dart';

// ─── Repository Provider ──────────────────────────────────────────────────────

final courtsRepositoryProvider = Provider<CourtsRepository>((ref) {
  return SupabaseCourtsRepository();
});

// ─── Courts State ─────────────────────────────────────────────────────────────

class CourtsState {
  final List<CourtEntity> courts;
  final List<CourtSlotEntity> slots;
  final bool isLoading;
  final String? error;
  final int selectedCourtIndex;
  final DateTime selectedDate;

  CourtsState({
    this.courts = const [],
    this.slots = const [],
    this.isLoading = false,
    this.error,
    this.selectedCourtIndex = 0,
    DateTime? selectedDate,
  }) : selectedDate = selectedDate ?? DateTime.now();

  CourtsState copyWith({
    List<CourtEntity>? courts,
    List<CourtSlotEntity>? slots,
    bool? isLoading,
    String? error,
    int? selectedCourtIndex,
    DateTime? selectedDate,
    bool clearError = false,
  }) {
    return CourtsState(
      courts: courts ?? this.courts,
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedCourtIndex: selectedCourtIndex ?? this.selectedCourtIndex,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

// ─── Courts Notifier ──────────────────────────────────────────────────────────

class CourtsNotifier extends Notifier<CourtsState> {
  CourtsRepository? _courtsRepository;
  RealtimeChannel? _slotsSubscription;

  @override
  CourtsState build() {
    _courtsRepository = ref.watch(courtsRepositoryProvider);
    ref.keepAlive();
    ref.onDispose(() {
      _slotsSubscription?.unsubscribe();
    });
    // Use Future.microtask to avoid triggering async state mutation during build
    Future.microtask(() => loadInitialData());
    return CourtsState();
  }

  Future<void> loadInitialData() async {
    if (state.courts.isNotEmpty) {
      await loadSlots();
      subscribeToSlots();
      return;
    }
    
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final courts = await _courtsRepository!.getCourts();
      state = state.copyWith(courts: courts, isLoading: false);
      if (courts.isNotEmpty) {
        await loadSlots();
        subscribeToSlots();
      }
    } catch (e) {
      debugPrint('Load courts error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      courts: [],
      selectedCourtIndex: 0,
    );
    await loadInitialData();
  }

  Future<void> loadSlots() async {
    if (state.courts.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final court = state.courts[state.selectedCourtIndex];
      final slots = await _courtsRepository!.getSlotsForCourtAndDate(
        courtId: court.id,
        date: state.selectedDate,
      );
      state = state.copyWith(slots: slots, isLoading: false);
    } catch (e) {
      debugPrint('Load slots error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void subscribeToSlots() {
    _slotsSubscription?.unsubscribe();
    if (state.courts.isEmpty) return;
    final court = state.courts[state.selectedCourtIndex];
    _slotsSubscription = _courtsRepository!.subscribeToSlots(
      courtId: court.id,
      date: state.selectedDate,
      onUpdate: (updatedSlots) {
        if (ref.mounted) state = state.copyWith(slots: updatedSlots);
      },
    );
  }

  void selectDate(DateTime date) {
    _slotsSubscription?.unsubscribe();
    state = state.copyWith(selectedDate: date);
    loadSlots();
    subscribeToSlots();
  }

  Future<void> addCourt(int courtNumber) async {
    try {
      final newCourt = await _courtsRepository!.addCourt(courtNumber: courtNumber);
      // Update local state by adding the new court and sorting
      final updatedCourts = [...state.courts, newCourt]..sort((a, b) => a.courtNumber.compareTo(b.courtNumber));
      state = state.copyWith(courts: updatedCourts);
    } catch (e) {
      debugPrint('Add court error: $e');
      rethrow;
    }
  }

  void selectCourt(int index) {
    _slotsSubscription?.unsubscribe();
    state = state.copyWith(selectedCourtIndex: index);
    loadSlots();
    subscribeToSlots();
  }

  Future<void> lockSlots(List<String> slotIds) async {
    try {
      await _courtsRepository!.updateSlotsStatus(slotIds: slotIds, status: 'BLOCKED');
      await loadSlots();
    } catch (e) {
      debugPrint('Lock slots error: $e');
      rethrow;
    }
  }

  Future<void> unlockSlots(List<String> slotIds) async {
    try {
      await _courtsRepository!.updateSlotsStatus(slotIds: slotIds, status: 'AVAILABLE');
      await loadSlots();
    } catch (e) {
      debugPrint('Unlock slots error: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> get slotsAsMap {
    final now = DateTime.now();
    final isToday = state.selectedDate.year == now.year &&
        state.selectedDate.month == now.month &&
        state.selectedDate.day == now.day;

    return state.slots.where((s) {
      if (!isToday) return true;
      final parts = s.startTime.split(':');
      if (parts.length < 2) return true;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final slotTime = DateTime(now.year, now.month, now.day, h, m);
      // Chỉ hiện các slot chưa bắt đầu hoặc mới bắt đầu trong vòng 10 phút
      return slotTime.isAfter(now.subtract(const Duration(minutes: 10)));
    }).map(
      (s) => s.toMap()
        ..['courtNumber'] = state.courts.isNotEmpty
            ? state.courts[state.selectedCourtIndex].courtNumber
            : 1,
    ).toList();
  }


  List<Map<String, dynamic>> get courtsAsMap => state.courts
      .map((c) => {'id': c.id, 'number': c.courtNumber, 'label': c.label})
      .toList();
}

// ─── Providers ────────────────────────────────────────────────────────────────

final courtsProvider = NotifierProvider<CourtsNotifier, CourtsState>(() {
  return CourtsNotifier();
});
