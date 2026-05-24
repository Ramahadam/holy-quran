import 'package:isar/isar.dart';

import '../../domain/models/reading_position.dart';
import '../local/entities/reading_position_entity.dart';
import '../local/isar_service.dart';
import 'reading_position_repository.dart';

class ReadingPositionRepositoryImpl implements ReadingPositionRepository {
  @override
  Future<void> savePosition(ReadingPosition position) async {
    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.readingPositionEntitys.clear();
      await isar.readingPositionEntitys
          .put(ReadingPositionEntity.fromDomain(position));
    });
  }

  @override
  Future<ReadingPosition?> getLastPosition() async {
    final isar = await IsarService.getInstance();
    final entity =
        await isar.readingPositionEntitys.where().sortByLastReadAtDesc().findFirst();
    return entity?.toDomain();
  }
}
