import '../../domain/models/bookmark.dart';
import '../../domain/models/reading_position.dart';
import '../repositories/bookmark_repository.dart';
import '../repositories/reading_position_repository.dart';
import 'quran_backup_codec.dart';

const minimumBackupPassphraseLength = 8;

class BackupRestoreException implements Exception {
  final Object restoreError;
  final Object rollbackError;

  const BackupRestoreException({
    required this.restoreError,
    required this.rollbackError,
  });

  @override
  String toString() =>
      'Backup restore and rollback failed: $restoreError; $rollbackError';
}

class QuranBackupService {
  final BookmarkRepository bookmarkRepository;
  final ReadingPositionRepository readingPositionRepository;
  final QuranBackupCodec codec;

  const QuranBackupService({
    required this.bookmarkRepository,
    required this.readingPositionRepository,
    required this.codec,
  });

  Future<List<int>> exportBackup(String passphrase) async {
    if (passphrase.trim().length < minimumBackupPassphraseLength) {
      throw const FormatException(
        'New backup passphrases must contain at least 8 characters.',
      );
    }
    final bookmarks = await bookmarkRepository.getAllBookmarks();
    final lastRead = await readingPositionRepository.getLastPosition();
    return codec.encode(
      QuranBackupData(
        bookmarks: bookmarks,
        lastRead: lastRead,
        exportedAt: DateTime.now(),
      ),
      passphrase,
    );
  }

  Future<void> importBackup(List<int> bytes, String passphrase) async {
    final data = await codec.decode(bytes, passphrase);
    final previousBookmarks = List<Bookmark>.unmodifiable(
      await bookmarkRepository.getAllBookmarks(),
    );
    final previousLastRead = await readingPositionRepository.getLastPosition();

    try {
      await _replaceState(data.bookmarks, data.lastRead);
    } catch (restoreError, restoreStackTrace) {
      try {
        await _replaceState(previousBookmarks, previousLastRead);
      } catch (rollbackError) {
        throw BackupRestoreException(
          restoreError: restoreError,
          rollbackError: rollbackError,
        );
      }
      Error.throwWithStackTrace(restoreError, restoreStackTrace);
    }
  }

  Future<void> _replaceState(
    List<Bookmark> bookmarks,
    ReadingPosition? lastRead,
  ) async {
    await bookmarkRepository.replaceAllBookmarks(
      List<Bookmark>.unmodifiable(bookmarks),
    );
    if (lastRead != null) {
      await readingPositionRepository.savePosition(lastRead);
    } else {
      await readingPositionRepository.clearPosition();
    }
  }
}
