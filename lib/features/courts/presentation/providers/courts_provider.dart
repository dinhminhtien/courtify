import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/config/supabase_config.dart';

// ─── Courts State ─────────────────────────────────────────────────────────────

class CourtsState {
  final List<Court> courts;
  final List<CourtSlot> slots;
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
    List<Court>? courts,
    List<CourtSlot>? slots,
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
  final CourtsService _courtsService = CourtsService();
  RealtimeChannel? _slotsSubscription;

  @override
  CourtsState build() {
    ref.onDispose(() {
      _slotsSubscription?.unsubscribe();
    });
    // Use Future.microtask to avoid triggering async state mutation during build
    Future.microtask(() => loadInitialData());
    return CourtsState();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final courts = await _courtsService.getCourts();
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

  Future<void> loadSlots() async {
    if (state.courts.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final court = state.courts[state.selectedCourtIndex];
      final slots = await _courtsService.getSlotsForCourtAndDate(
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
    _slotsSubscription = _courtsService.subscribeToSlots(
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

  void selectCourt(int index) {
    _slotsSubscription?.unsubscribe();
    state = state.copyWith(selectedCourtIndex: index);
    loadSlots();
    subscribeToSlots();
  }

  List<Map<String, dynamic>> get slotsAsMap => state.slots
      .map(
        (s) => s.toMap()
          ..['courtNumber'] = state.courts.isNotEmpty
              ? state.courts[state.selectedCourtIndex].courtNumber
              : 1,
      )
      .toList();

  List<Map<String, dynamic>> get courtsAsMap => state.courts
      .map((c) => {'id': c.id, 'number': c.courtNumber, 'label': c.label})
      .toList();
}

// ─── Providers ────────────────────────────────────────────────────────────────

final courtsProvider = NotifierProvider<CourtsNotifier, CourtsState>(() {
  return CourtsNotifier();
});
