import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/backup/quran_backup_codec.dart';
import 'package:holy_quran_app/data/backup/quran_backup_service.dart';
import 'package:holy_quran_app/data/repositories/bookmark_repository.dart';
import 'package:holy_quran_app/data/repositories/reading_position_repository.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';

QuranBackupCodec _testCodec() {
  return QuranBackupCodec(
    kdf: Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 1, bits: 256),
  );
}

void main() {
  group('QuranBackupCodec', () {
    test('encrypts and decrypts bookmarks and last-read state', () async {
      final codec = _testCodec();
      final data = QuranBackupData(
        bookmarks: [
          Bookmark(
            verseId: '2:255',
            timestamp: DateTime.utc(2026, 5, 30),
            note: 'Ayat al-Kursi',
          ),
        ],
        lastRead: ReadingPosition(
          verseId: '18:10',
          lastReadAt: DateTime.utc(2026, 5, 29),
        ),
        exportedAt: DateTime.utc(2026, 5, 30, 12),
      );

      final bytes = await codec.encode(data, 'correct horse battery staple');
      final decoded = await codec.decode(bytes, 'correct horse battery staple');

      expect(String.fromCharCodes(bytes), isNot(contains('Ayat al-Kursi')));
      expect(decoded.bookmarks.single.verseId, '2:255');
      expect(decoded.bookmarks.single.note, 'Ayat al-Kursi');
      expect(decoded.lastRead?.verseId, '18:10');
      expect(decoded.exportedAt, DateTime.utc(2026, 5, 30, 12));
    });

    test('rejects the wrong passphrase', () async {
      final codec = _testCodec();
      final bytes = await codec.encode(
        QuranBackupData(
          bookmarks: const [],
          lastRead: null,
          exportedAt: DateTime.utc(2026, 5, 30),
        ),
        'right passphrase',
      );

      await expectLater(
        codec.decode(bytes, 'wrong passphrase'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('QuranBackupService', () {
    test('exports repository state', () async {
      final bookmarkRepo = _FakeBookmarkRepository([
        Bookmark(verseId: '1:1', timestamp: DateTime.utc(2026, 5, 30)),
      ]);
      final positionRepo = _FakeReadingPositionRepository(
        ReadingPosition(verseId: '1:7', lastReadAt: DateTime.utc(2026, 5, 30)),
      );
      final service = QuranBackupService(
        bookmarkRepository: bookmarkRepo,
        readingPositionRepository: positionRepo,
        codec: _testCodec(),
      );

      final bytes = await service.exportBackup('passphrase');
      final decoded = await _testCodec().decode(bytes, 'passphrase');

      expect(decoded.bookmarks.single.verseId, '1:1');
      expect(decoded.lastRead?.verseId, '1:7');
    });

    test('validates import before applying restored state', () async {
      final bookmarkRepo = _FakeBookmarkRepository([
        Bookmark(verseId: '1:1', timestamp: DateTime.utc(2026, 5, 30)),
      ]);
      final positionRepo = _FakeReadingPositionRepository(null);
      final service = QuranBackupService(
        bookmarkRepository: bookmarkRepo,
        readingPositionRepository: positionRepo,
        codec: _testCodec(),
      );

      await expectLater(
        service.importBackup('not json'.codeUnits, 'passphrase'),
        throwsA(isA<Exception>()),
      );

      expect(bookmarkRepo.replaced, isFalse);
      expect(positionRepo.savedPosition, isNull);
    });

    test('clears stale last-read state when backup has none', () async {
      final bookmarkRepo = _FakeBookmarkRepository([]);
      final positionRepo = _FakeReadingPositionRepository(
        ReadingPosition(verseId: '2:1', lastReadAt: DateTime.utc(2026, 5, 29)),
      );
      final service = QuranBackupService(
        bookmarkRepository: bookmarkRepo,
        readingPositionRepository: positionRepo,
        codec: _testCodec(),
      );
      final bytes = await _testCodec().encode(
        QuranBackupData(
          bookmarks: const [],
          lastRead: null,
          exportedAt: DateTime.utc(2026, 5, 30),
        ),
        'passphrase',
      );

      await service.importBackup(bytes, 'passphrase');

      expect(positionRepo.savedPosition, isNull);
      expect(positionRepo.cleared, isTrue);
    });
  });
}

class _FakeBookmarkRepository implements BookmarkRepository {
  List<Bookmark> bookmarks;
  bool replaced = false;

  _FakeBookmarkRepository(this.bookmarks);

  @override
  Future<void> addBookmark(String verseId, DateTime timestamp) async {
    await saveBookmark(Bookmark(verseId: verseId, timestamp: timestamp));
  }

  @override
  Future<List<Bookmark>> getAllBookmarks() async => bookmarks;

  @override
  Future<Set<String>> getBookmarkedVerseIdsBySurah(int surahNumber) async {
    return bookmarks
        .where((bookmark) => bookmark.verseId.startsWith('$surahNumber:'))
        .map((bookmark) => bookmark.verseId)
        .toSet();
  }

  @override
  Future<List<Bookmark>> getRecentBookmarks({int limit = 3}) async {
    return bookmarks.take(limit).toList();
  }

  @override
  Future<void> removeBookmark(String verseId) async {
    bookmarks = bookmarks
        .where((bookmark) => bookmark.verseId != verseId)
        .toList();
  }

  @override
  Future<void> replaceAllBookmarks(List<Bookmark> bookmarks) async {
    replaced = true;
    this.bookmarks = bookmarks;
  }

  @override
  Future<void> saveBookmark(Bookmark bookmark) async {
    bookmarks = [
      ...bookmarks.where((item) => item.verseId != bookmark.verseId),
      bookmark,
    ];
  }
}

class _FakeReadingPositionRepository implements ReadingPositionRepository {
  ReadingPosition? savedPosition;
  bool cleared = false;

  _FakeReadingPositionRepository(this.savedPosition);

  @override
  Future<void> clearPosition() async {
    savedPosition = null;
    cleared = true;
  }

  @override
  Future<ReadingPosition?> getLastPosition() async => savedPosition;

  @override
  Future<void> savePosition(ReadingPosition position) async {
    savedPosition = position;
    cleared = false;
  }
}
