import 'package:courtify/domain/entities/court.dart';
import 'package:courtify/domain/entities/slot.dart';

abstract class ICourtRepository {
  Future<List<Court>> getAllCourts();
  Future<List<Slot>> getSlotsByCourt(int courtId, DateTime date);
  Future<List<Slot>> getSlotsByDate(DateTime date);
}
