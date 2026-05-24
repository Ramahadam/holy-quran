import '../../domain/models/reading_position.dart';

abstract class ReadingPositionRepository {
  Future<void> savePosition(ReadingPosition position);

  Future<ReadingPosition?> getLastPosition();
}
