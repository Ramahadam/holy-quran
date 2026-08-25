import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/backup/quran_backup_codec.dart';
import 'package:holy_quran_app/data/backup/quran_backup_service.dart';
import 'package:holy_quran_app/data/local/entities/bookmark_entity.dart';
import 'package:holy_quran_app/data/local/entities/quran_data_metadata_entity.dart';
import 'package:holy_quran_app/data/local/entities/reading_position_entity.dart';
import 'package:holy_quran_app/data/local/entities/surah_entity.dart';
import 'package:holy_quran_app/data/local/entities/verse_entity.dart';
import 'package:holy_quran_app/data/local/isar_service.dart';
import 'package:holy_quran_app/data/repositories/bookmark_repository_impl.dart';
import 'package:holy_quran_app/data/repositories/quran_repository.dart';
import 'package:holy_quran_app/data/repositories/reading_position_repository_impl.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:holy_quran_app/domain/models/reading_position.dart';
import 'package:holy_quran_app/domain/models/surah.dart';
import 'package:isar/isar.dart';

void main() {
  late Directory databaseDirectory;
  late Isar database;
  late BookmarkRepositoryImpl bookmarkRepository;
  late ReadingPositionRepositoryImpl readingPositionRepository;

  setUpAll(_initializeIsarForTests);

  setUp(() async {
    databaseDirectory = await Directory.systemTemp.createTemp(
      'holy-quran-persistence-test-',
    );
    database = await Isar.open(
      [
        VerseEntitySchema,
        SurahEntitySchema,
        BookmarkEntitySchema,
        ReadingPositionEntitySchema,
        QuranDataMetadataEntitySchema,
      ],
      directory: databaseDirectory.path,
      name: 'persistence-${DateTime.now().microsecondsSinceEpoch}',
    );
    await IsarService.getInstanceForTesting(() async => database);
    bookmarkRepository = BookmarkRepositoryImpl();
    readingPositionRepository = ReadingPositionRepositoryImpl();
  });

  tearDown(() async {
    await IsarService.close();
    await databaseDirectory.delete(recursive: true);
  });

  test(
    'bookmarks replace atomically and return in newest-first order',
    () async {
      await bookmarkRepository.saveBookmark(
        Bookmark(verseId: '1:1', timestamp: DateTime.utc(2026, 1, 1)),
      );
      await bookmarkRepository.saveBookmark(
        Bookmark(verseId: '2:255', timestamp: DateTime.utc(2026, 1, 3)),
      );
      await bookmarkRepository.saveBookmark(
        Bookmark(verseId: '2:256', timestamp: DateTime.utc(2026, 1, 2)),
      );

      expect(
        (await bookmarkRepository.getAllBookmarks()).map(
          (bookmark) => bookmark.verseId,
        ),
        ['2:255', '2:256', '1:1'],
      );
      expect(
        (await bookmarkRepository.getRecentBookmarks(
          limit: 2,
        )).map((bookmark) => bookmark.verseId),
        ['2:255', '2:256'],
      );
      expect(await bookmarkRepository.getBookmarkedVerseIdsBySurah(2), {
        '2:255',
        '2:256',
      });

      await bookmarkRepository.replaceAllBookmarks([
        Bookmark(verseId: '18:10', timestamp: DateTime.utc(2026, 1, 4)),
      ]);

      expect(
        (await bookmarkRepository.getAllBookmarks()).map(
          (bookmark) => bookmark.verseId,
        ),
        ['18:10'],
      );
    },
  );

  test('reading position keeps one current value and clears it', () async {
    await readingPositionRepository.savePosition(
      ReadingPosition(verseId: '1:7', lastReadAt: DateTime.utc(2026, 1, 1)),
    );
    await readingPositionRepository.savePosition(
      ReadingPosition(verseId: '2:255', lastReadAt: DateTime.utc(2026, 1, 2)),
    );

    final currentPosition = await readingPositionRepository.getLastPosition();
    expect(currentPosition?.verseId, '2:255');
    expect(await database.readingPositionEntitys.count(), 1);

    await readingPositionRepository.clearPosition();

    expect(await readingPositionRepository.getLastPosition(), isNull);
    expect(await database.readingPositionEntitys.count(), 0);
  });

  test(
    'encrypted backup replaces the persisted bookmark and reading state',
    () async {
      await bookmarkRepository.saveBookmark(
        Bookmark(verseId: '1:1', timestamp: DateTime.utc(2026, 1, 1)),
      );
      await readingPositionRepository.savePosition(
        ReadingPosition(verseId: '1:7', lastReadAt: DateTime.utc(2026, 1, 1)),
      );
      final codec = _testCodec();
      final service = QuranBackupService(
        bookmarkRepository: bookmarkRepository,
        readingPositionRepository: readingPositionRepository,
        quranRepository: _FakeQuranRepository(),
        codec: codec,
      );

      final exported = await service.exportBackup('passphrase');
      final exportedData = await codec.decode(exported, 'passphrase');
      expect(exportedData.bookmarks.single.verseId, '1:1');
      expect(exportedData.lastRead?.verseId, '1:7');

      final replacement = await codec.encode(
        QuranBackupData(
          bookmarks: [
            Bookmark(verseId: '2:255', timestamp: DateTime.utc(2026, 1, 2)),
          ],
          lastRead: ReadingPosition(
            verseId: '2:255',
            lastReadAt: DateTime.utc(2026, 1, 2),
          ),
          exportedAt: DateTime.utc(2026, 1, 2),
        ),
        'passphrase',
      );

      await service.importBackup(replacement, 'passphrase');

      expect(
        (await bookmarkRepository.getAllBookmarks()).single.verseId,
        '2:255',
      );
      expect(
        (await readingPositionRepository.getLastPosition())?.verseId,
        '2:255',
      );
    },
  );

  test('invalid backup data leaves persisted state unchanged', () async {
    await bookmarkRepository.saveBookmark(
      Bookmark(verseId: '1:1', timestamp: DateTime.utc(2026, 1, 1)),
    );
    await readingPositionRepository.savePosition(
      ReadingPosition(verseId: '1:7', lastReadAt: DateTime.utc(2026, 1, 1)),
    );
    final service = QuranBackupService(
      bookmarkRepository: bookmarkRepository,
      readingPositionRepository: readingPositionRepository,
      quranRepository: _FakeQuranRepository(),
      codec: _testCodec(),
    );

    await expectLater(
      service.importBackup(utf8.encode('not a backup'), 'passphrase'),
      throwsFormatException,
    );

    expect((await bookmarkRepository.getAllBookmarks()).single.verseId, '1:1');
    expect((await readingPositionRepository.getLastPosition())?.verseId, '1:7');
  });
}

class _FakeQuranRepository extends Fake implements QuranRepository {
  @override
  Future<List<Surah>> getAllSurahs() async => const [
    Surah(
      surahNumber: 1,
      nameArabic: 'الفاتحة',
      nameEnglish: 'Al-Fatihah',
      numberOfVerses: 7,
    ),
    Surah(
      surahNumber: 2,
      nameArabic: 'البقرة',
      nameEnglish: 'Al-Baqarah',
      numberOfVerses: 286,
    ),
  ];
}

QuranBackupCodec _testCodec() {
  return QuranBackupCodec(
    kdf: Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 1, bits: 256),
  );
}

Future<void> _initializeIsarForTests() async {
  final packageConfigFile = File('.dart_tool/package_config.json');
  final packageConfig =
      jsonDecode(await packageConfigFile.readAsString()) as Map;
  final packages = packageConfig['packages'] as List;
  final isarFlutterLibs = packages.cast<Map>().singleWhere(
    (package) => package['name'] == 'isar_flutter_libs',
  );
  final packageRoot = Directory.fromUri(
    packageConfigFile.absolute.uri.resolve(
      isarFlutterLibs['rootUri'] as String,
    ),
  ).uri;
  final libraryFile = switch (Platform.operatingSystem) {
    'macos' => 'macos/libisar.dylib',
    'linux' => 'linux/libisar.so',
    'windows' => 'windows/isar.dll',
    _ => throw UnsupportedError('Persistence tests require a desktop host.'),
  };
  final libraryPath = packageRoot.resolve(libraryFile).toFilePath();
  await Isar.initializeIsarCore(libraries: {Abi.current(): libraryPath});
}
