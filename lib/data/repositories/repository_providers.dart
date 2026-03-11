import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courtify/core/database/supabase_config.dart';
import 'package:courtify/data/datasources/remote/booking_remote_data_source.dart';
import 'package:courtify/data/repositories/booking_repository_impl.dart';
import 'package:courtify/domain/repositories/i_booking_repository.dart';

final bookingRemoteDataSourceProvider = Provider<IBookingRemoteDataSource>((ref) {
  return BookingRemoteDataSource(SupabaseConfig.client);
});

final bookingRepositoryProvider = Provider<IBookingRepository>((ref) {
  final dataSource = ref.watch(bookingRemoteDataSourceProvider);
  return BookingRepositoryImpl(dataSource);
});
