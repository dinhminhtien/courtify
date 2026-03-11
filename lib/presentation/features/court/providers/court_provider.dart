import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courtify/core/database/supabase_config.dart';
import 'package:courtify/data/datasources/remote/court_remote_data_source.dart';
import 'package:courtify/data/repositories/court_repository_impl.dart';
import 'package:courtify/domain/repositories/i_court_repository.dart';
import 'package:courtify/domain/entities/slot.dart';

final courtRemoteDataSourceProvider = Provider<ICourtRemoteDataSource>((ref) {
  return CourtRemoteDataSource(SupabaseConfig.client);
});

final courtRepositoryProvider = Provider<ICourtRepository>((ref) {
  final remoteDataSource = ref.watch(courtRemoteDataSourceProvider);
  return CourtRepositoryImpl(remoteDataSource);
});

final courtsProvider = FutureProvider((ref) {
  final repository = ref.watch(courtRepositoryProvider);
  return repository.getAllCourts();
});

final slotsByCourtProvider = FutureProvider.family<List<Slot>, ({int courtId, DateTime date})>((ref, arg) {
  final repository = ref.watch(courtRepositoryProvider);
  return repository.getSlotsByCourt(arg.courtId, arg.date);
});

final allSlotsByDateProvider = FutureProvider.family<List<Slot>, DateTime>((ref, date) {
  final repository = ref.watch(courtRepositoryProvider);
  return repository.getSlotsByDate(date);
});
