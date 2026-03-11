import 'package:courtify/data/datasources/remote/court_remote_data_source.dart';
import 'package:courtify/domain/entities/court.dart';
import 'package:courtify/domain/entities/slot.dart';
import 'package:courtify/domain/repositories/i_court_repository.dart';

class CourtRepositoryImpl implements ICourtRepository {
  final ICourtRemoteDataSource remoteDataSource;

  CourtRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Court>> getAllCourts() async {
    return await remoteDataSource.getAllCourts();
  }

  @override
  Future<List<Slot>> getSlotsByCourt(int courtId, DateTime date) async {
    final dateString = date.toIso8601String().split('T')[0];
    return await remoteDataSource.getSlotsByCourt(courtId, dateString);
  }

  @override
  Future<List<Slot>> getSlotsByDate(DateTime date) async {
    final dateString = date.toIso8601String().split('T')[0];
    return await remoteDataSource.getSlotsByDate(dateString);
  }
}
