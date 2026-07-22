import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/backup/quran_backup_codec.dart';
import 'package:holy_quran_app/data/backup/quran_backup_file_operations.dart';
import 'package:holy_quran_app/data/backup/quran_backup_file_service.dart';
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

    test('requires at least 8 characters for a new backup passphrase', () {
      final service = QuranBackupService(
        bookmarkRepository: _FakeBookmarkRepository([]),
        readingPositionRepository: _FakeReadingPositionRepository(null),
        codec: _testCodec(),
      );

      expect(
        () => service.exportBackup('1234567'),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'can restore a legacy backup protected by a short passphrase',
      () async {
        final codec = _testCodec();
        final bytes = await codec.encode(
          QuranBackupData(
            bookmarks: [
              Bookmark(verseId: '1:1', timestamp: DateTime.utc(2026, 5, 30)),
            ],
            lastRead: null,
            exportedAt: DateTime.utc(2026, 5, 30),
          ),
          'old',
        );
        final bookmarkRepo = _FakeBookmarkRepository([]);
        final service = QuranBackupService(
          bookmarkRepository: bookmarkRepo,
          readingPositionRepository: _FakeReadingPositionRepository(null),
          codec: codec,
        );

        await service.importBackup(bytes, 'old');

        expect(bookmarkRepo.bookmarks.single.verseId, '1:1');
      },
    );

    test('round trips exported state into a fresh repository', () async {
      final sourceBookmarks = [
        Bookmark(
          verseId: '2:255',
          timestamp: DateTime.utc(2026, 5, 30, 10),
          note: 'Ayat al-Kursi',
        ),
        Bookmark(verseId: '18:10', timestamp: DateTime.utc(2026, 5, 30, 11)),
      ];
      final sourcePosition = ReadingPosition(
        verseId: '36:12',
        lastReadAt: DateTime.utc(2026, 5, 30, 12),
      );
      final sourceService = QuranBackupService(
        bookmarkRepository: _FakeBookmarkRepository(sourceBookmarks),
        readingPositionRepository: _FakeReadingPositionRepository(
          sourcePosition,
        ),
        codec: _testCodec(),
      );
      final targetBookmarkRepo = _FakeBookmarkRepository([
        Bookmark(verseId: '1:1', timestamp: DateTime.utc(2026, 5, 29)),
      ]);
      final targetPositionRepo = _FakeReadingPositionRepository(
        ReadingPosition(verseId: '1:7', lastReadAt: DateTime.utc(2026, 5, 29)),
      );
      final targetService = QuranBackupService(
        bookmarkRepository: targetBookmarkRepo,
        readingPositionRepository: targetPositionRepo,
        codec: _testCodec(),
      );

      final bytes = await sourceService.exportBackup('round trip passphrase');
      await targetService.importBackup(bytes, 'round trip passphrase');

      expect(targetBookmarkRepo.bookmarks, hasLength(2));
      expect(targetBookmarkRepo.bookmarks.map((item) => item.verseId), [
        '2:255',
        '18:10',
      ]);
      expect(targetBookmarkRepo.bookmarks.first.note, 'Ayat al-Kursi');
      expect(targetPositionRepo.savedPosition?.verseId, '36:12');
      expect(
        targetPositionRepo.savedPosition?.lastReadAt,
        sourcePosition.lastReadAt,
      );
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

    test('rolls back existing state when applying a restore fails', () async {
      final originalBookmark = Bookmark(
        verseId: '1:1',
        timestamp: DateTime.utc(2026, 5, 29),
      );
      final originalPosition = ReadingPosition(
        verseId: '1:7',
        lastReadAt: DateTime.utc(2026, 5, 29),
      );
      final bookmarkRepo = _FakeBookmarkRepository([originalBookmark]);
      final positionRepo = _FakeReadingPositionRepository(
        originalPosition,
        saveFailuresRemaining: 1,
      );
      final codec = _testCodec();
      final service = QuranBackupService(
        bookmarkRepository: bookmarkRepo,
        readingPositionRepository: positionRepo,
        codec: codec,
      );
      final bytes = await codec.encode(
        QuranBackupData(
          bookmarks: [
            Bookmark(verseId: '2:255', timestamp: DateTime.utc(2026, 5, 30)),
          ],
          lastRead: ReadingPosition(
            verseId: '2:255',
            lastReadAt: DateTime.utc(2026, 5, 30),
          ),
          exportedAt: DateTime.utc(2026, 5, 30),
        ),
        'passphrase',
      );

      await expectLater(
        service.importBackup(bytes, 'passphrase'),
        throwsA(isA<StateError>()),
      );

      expect(bookmarkRepo.bookmarks.single.verseId, originalBookmark.verseId);
      expect(positionRepo.savedPosition?.verseId, originalPosition.verseId);
    });
  });

  group('QuranBackupFileService', () {
    test(
      'saves an encrypted backup through the selected file operation',
      () async {
        final operations = _FakeBackupFileOperations();
        final service = _fileService(operations: operations);

        final result = await service.saveBackup(
          'passphrase',
          confirmButtonText: 'Save',
        );

        expect(result, BackupFileOperationResult.completed);
        expect(operations.savedBytes, isNotEmpty);
        expect(operations.saveConfirmButtonText, 'Save');
        expect(
          String.fromCharCodes(operations.savedBytes!),
          isNot(contains('private note')),
        );
      },
    );

    test('preserves an unavailable share result', () async {
      final operations = _FakeBackupFileOperations(
        shareResult: BackupFileOperationResult.unavailable,
      );
      final service = _fileService(operations: operations);

      final result = await service.shareBackup(
        'passphrase',
        subject: 'Backup',
        title: 'Share backup',
      );

      expect(result, BackupFileOperationResult.unavailable);
      expect(operations.shareSubject, 'Backup');
      expect(operations.shareTitle, 'Share backup');
    });

    test('preserves a canceled device save result', () async {
      final operations = _FakeBackupFileOperations(
        saveResult: BackupFileOperationResult.canceled,
      );

      final result = await _fileService(
        operations: operations,
      ).saveBackup('passphrase', confirmButtonText: 'Save');

      expect(result, BackupFileOperationResult.canceled);
    });

    test('does not restore anything when file selection is canceled', () async {
      final bookmarkRepo = _FakeBookmarkRepository([]);
      final operations = _FakeBackupFileOperations(pickedBytes: null);
      final service = _fileService(
        operations: operations,
        bookmarkRepository: bookmarkRepo,
      );

      final result = await service.restoreBackup(
        'passphrase',
        confirmButtonText: 'Restore',
      );

      expect(result, BackupFileOperationResult.canceled);
      expect(bookmarkRepo.replaced, isFalse);
    });
  });
}

QuranBackupFileService _fileService({
  required _FakeBackupFileOperations operations,
  _FakeBookmarkRepository? bookmarkRepository,
}) {
  return QuranBackupFileService(
    backupService: QuranBackupService(
      bookmarkRepository:
          bookmarkRepository ??
          _FakeBookmarkRepository([
            Bookmark(
              verseId: '2:255',
              timestamp: DateTime.utc(2026, 5, 30),
              note: 'private note',
            ),
          ]),
      readingPositionRepository: _FakeReadingPositionRepository(null),
      codec: _testCodec(),
    ),
    fileOperations: operations,
  );
}

class _FakeBackupFileOperations implements BackupFileOperations {
  final BackupFileOperationResult saveResult;
  final BackupFileOperationResult shareResult;
  final Uint8List? pickedBytes;
  Uint8List? savedBytes;
  String? saveConfirmButtonText;
  String? shareSubject;
  String? shareTitle;

  _FakeBackupFileOperations({
    this.saveResult = BackupFileOperationResult.completed,
    this.shareResult = BackupFileOperationResult.completed,
    this.pickedBytes,
  });

  @override
  Future<Uint8List?> pick({required String confirmButtonText}) async =>
      pickedBytes;

  @override
  Future<BackupFileOperationResult> save({
    required Uint8List bytes,
    required String confirmButtonText,
  }) async {
    savedBytes = bytes;
    saveConfirmButtonText = confirmButtonText;
    return saveResult;
  }

  @override
  Future<BackupFileOperationResult> share({
    required Uint8List bytes,
    required String subject,
    required String title,
  }) async {
    shareSubject = subject;
    shareTitle = title;
    return shareResult;
  }
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
  int saveFailuresRemaining;

  _FakeReadingPositionRepository(
    this.savedPosition, {
    this.saveFailuresRemaining = 0,
  });

  @override
  Future<void> clearPosition() async {
    savedPosition = null;
    cleared = true;
  }

  @override
  Future<ReadingPosition?> getLastPosition() async => savedPosition;

  @override
  Future<void> savePosition(ReadingPosition position) async {
    if (saveFailuresRemaining > 0) {
      saveFailuresRemaining--;
      throw StateError('Simulated save failure');
    }
    savedPosition = position;
    cleared = false;
  }
}
