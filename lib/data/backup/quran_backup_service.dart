import '../../domain/models/bookmark.dart';
import '../repositories/bookmark_repository.dart';
import '../repositories/reading_position_repository.dart';
import 'quran_backup_codec.dart';

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
    await bookmarkRepository.replaceAllBookmarks(
      List<Bookmark>.unmodifiable(data.bookmarks),
    );
    final lastRead = data.lastRead;
    if (lastRead != null) {
      await readingPositionRepository.savePosition(lastRead);
    } else {
      await readingPositionRepository.clearPosition();
    }
  }
}
