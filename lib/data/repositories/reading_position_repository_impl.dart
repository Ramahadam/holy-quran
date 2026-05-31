import '../../domain/models/reading_position.dart';
import '../local/entities/reading_position_entity.dart';
import '../local/isar_service.dart';
import 'reading_position_repository.dart';

class ReadingPositionRepositoryImpl implements ReadingPositionRepository {
  // Invariant: at most one row exists in this collection at all times.
  // We enforce this by always writing to a fixed ID (1), which acts as an upsert.
  static const int _singletonId = 1;

  @override
  Future<void> savePosition(ReadingPosition position) async {
    final isar = await IsarService.getInstance();
    final entity = ReadingPositionEntity.fromDomain(position)
      ..id = _singletonId;
    await isar.writeTxn(() async {
      await isar.readingPositionEntitys.put(entity);
    });
  }

  @override
  Future<ReadingPosition?> getLastPosition() async {
    final isar = await IsarService.getInstance();
    final entity = await isar.readingPositionEntitys.get(_singletonId);
    return entity?.toDomain();
  }

  @override
  Future<void> clearPosition() async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.readingPositionEntitys.delete(_singletonId);
    });
  }
}
