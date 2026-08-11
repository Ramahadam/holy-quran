import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/core/utils/checksum_validator.dart';
import 'package:holy_quran_app/data/local/entities/bookmark_entity.dart';
import 'package:holy_quran_app/data/local/entities/quran_data_metadata_entity.dart';
import 'package:holy_quran_app/data/local/entities/reading_position_entity.dart';
import 'package:holy_quran_app/data/local/entities/surah_entity.dart';
import 'package:holy_quran_app/data/local/entities/verse_entity.dart';
import 'package:holy_quran_app/data/repositories/quran_repository_impl.dart';
import 'package:holy_quran_app/domain/models/bookmark.dart';
import 'package:isar/isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> bundledAssets;
  late Directory databaseDirectory;
  late Isar database;

  setUpAll(() async {
    await _initializeIsarForTests();
    bundledAssets = {
      'assets/quran/checksums.txt': await rootBundle.loadString(
        'assets/quran/checksums.txt',
      ),
      'assets/quran/surahs.json': await rootBundle.loadString(
        'assets/quran/surahs.json',
      ),
      'assets/quran/verses.json': await rootBundle.loadString(
        'assets/quran/verses.json',
      ),
    };
  });

  setUp(() async {
    databaseDirectory = await Directory.systemTemp.createTemp(
      'holy-quran-upgrade-test-',
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
      name: 'quran-upgrade-${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await database.close(deleteFromDisk: true);
    await databaseDirectory.delete(recursive: true);
  });

  test('installs changed bundled Quran content and keeps bookmarks', () async {
    final currentRepository = _repository(database, bundledAssets);
    expect(await currentRepository.isDataLoaded(), isFalse);
    await currentRepository.loadQuranData();
    expect(await database.surahEntitys.count(), 114);
    expect(await database.verseEntitys.count(), 6236);
    await database.writeTxn(() async {
      await database.bookmarkEntitys.putByVerseId(
        BookmarkEntity.fromDomain(
          Bookmark(verseId: '2:255', timestamp: DateTime.utc(2026, 1, 1)),
        ),
      );
      await database.readingPositionEntitys.put(
        ReadingPositionEntity()
          ..id = 1
          ..verseId = '2:255'
          ..lastReadAt = DateTime.utc(2026, 1, 1),
      );
    });

    final updatedAssets = _withUpdatedVerseTranslation(
      bundledAssets,
      verseId: '1:1',
      translation: 'Updated verified translation',
    );
    final updatedRepository = _repository(database, updatedAssets);

    expect(await updatedRepository.isDataLoaded(), isFalse);
    await updatedRepository.loadQuranData();

    final upgradedVerse = await database.verseEntitys
        .filter()
        .verseIdEqualTo('1:1')
        .findFirst();
    expect(upgradedVerse?.translation, 'Updated verified translation');
    expect(await updatedRepository.isDataLoaded(), isTrue);
    expect(await database.bookmarkEntitys.count(), 1);
    expect((await database.readingPositionEntitys.get(1))?.verseId, '2:255');
  });

  test('keeps an unchanged verified Quran installation ready', () async {
    final repository = _repository(database, bundledAssets);
    await repository.loadQuranData();

    expect(await repository.isDataLoaded(), isTrue);
    await repository.loadQuranData();

    expect(await repository.isDataLoaded(), isTrue);
    expect(await database.surahEntitys.count(), 114);
    expect(await database.verseEntitys.count(), 6236);
    expect(await database.quranDataMetadataEntitys.count(), 1);
  });

  test(
    'preserves installed Quran content when an upgrade checksum fails',
    () async {
      final repository = _repository(database, bundledAssets);
      await repository.loadQuranData();
      final installedVerse = await database.verseEntitys
          .filter()
          .verseIdEqualTo('1:1')
          .findFirst();

      final invalidAssets = Map<String, String>.from(bundledAssets)
        ..['assets/quran/checksums.txt'] =
            bundledAssets['assets/quran/checksums.txt']!.replaceFirst(
              RegExp(
                r'^[a-f0-9]{64}(?=  assets/quran/verses\.json$)',
                multiLine: true,
              ),
              '0' * 64,
            );
      final invalidRepository = _repository(database, invalidAssets);

      expect(invalidRepository.loadQuranData(), throwsException);

      final preservedVerse = await database.verseEntitys
          .filter()
          .verseIdEqualTo('1:1')
          .findFirst();
      expect(preservedVerse?.translation, installedVerse?.translation);
      expect(await repository.isDataLoaded(), isTrue);
    },
  );

  test(
    'preserves installed Quran content when upgraded JSON is invalid',
    () async {
      final repository = _repository(database, bundledAssets);
      await repository.loadQuranData();
      final installedVerseCount = await database.verseEntitys.count();

      const invalidVerses = '{not-json';
      final invalidAssets = Map<String, String>.from(bundledAssets)
        ..['assets/quran/verses.json'] = invalidVerses
        ..['assets/quran/checksums.txt'] = _checksumsFor(
          bundledAssets['assets/quran/surahs.json']!,
          invalidVerses,
        );

      expect(
        _repository(database, invalidAssets).loadQuranData(),
        throwsFormatException,
      );

      expect(await database.verseEntitys.count(), installedVerseCount);
      expect(await repository.isDataLoaded(), isTrue);
    },
  );

  test(
    'rolls back Quran content when the database replacement fails',
    () async {
      final repository = _repository(database, bundledAssets);
      await repository.loadQuranData();
      final installedVerse = await database.verseEntitys
          .filter()
          .verseIdEqualTo('1:2')
          .findFirst();

      final invalidAssets = _withDuplicateVerseId(bundledAssets);

      expect(
        _repository(database, invalidAssets).loadQuranData(),
        throwsA(isA<IsarError>()),
      );

      final preservedVerse = await database.verseEntitys
          .filter()
          .verseIdEqualTo('1:2')
          .findFirst();
      expect(preservedVerse?.arabicText, installedVerse?.arabicText);
      expect(await database.surahEntitys.count(), 114);
      expect(await database.verseEntitys.count(), 6236);
      expect(await repository.isDataLoaded(), isTrue);
    },
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
  late final String libraryFile;
  if (Platform.isMacOS) {
    libraryFile = 'macos/libisar.dylib';
  } else if (Platform.isLinux) {
    libraryFile = 'linux/libisar.so';
  } else if (Platform.isWindows) {
    libraryFile = 'windows/isar.dll';
  } else {
    throw UnsupportedError('Isar upgrade tests require a desktop host.');
  }
  final libraryPath = packageRoot.resolve(libraryFile).toFilePath();
  await Isar.initializeIsarCore(libraries: {Abi.current(): libraryPath});
}

QuranRepositoryImpl _repository(Isar database, Map<String, String> assets) {
  return QuranRepositoryImpl(
    assetBundle: _StringAssetBundle(assets),
    getDatabase: () async => database,
  );
}

Map<String, String> _withUpdatedVerseTranslation(
  Map<String, String> assets, {
  required String verseId,
  required String translation,
}) {
  final verses = (jsonDecode(assets['assets/quran/verses.json']!) as List)
      .cast<Map<String, dynamic>>();
  final updatedVerses = verses
      .map((verse) {
        if (verse['verseId'] != verseId) return verse;
        return <String, dynamic>{...verse, 'translation': translation};
      })
      .toList(growable: false);
  final versesJson = jsonEncode(updatedVerses);
  return {
    ...assets,
    'assets/quran/verses.json': versesJson,
    'assets/quran/checksums.txt': _checksumsFor(
      assets['assets/quran/surahs.json']!,
      versesJson,
    ),
  };
}

Map<String, String> _withDuplicateVerseId(Map<String, String> assets) {
  final verses = (jsonDecode(assets['assets/quran/verses.json']!) as List)
      .cast<Map<String, dynamic>>();
  final duplicateVerseId = verses.first['verseId'];
  final updatedVerses = verses
      .asMap()
      .entries
      .map((entry) {
        if (entry.key != 1) return entry.value;
        return <String, dynamic>{...entry.value, 'verseId': duplicateVerseId};
      })
      .toList(growable: false);
  final versesJson = jsonEncode(updatedVerses);
  return {
    ...assets,
    'assets/quran/verses.json': versesJson,
    'assets/quran/checksums.txt': _checksumsFor(
      assets['assets/quran/surahs.json']!,
      versesJson,
    ),
  };
}

String _checksumsFor(String surahsJson, String versesJson) {
  return '${ChecksumValidator.calculateSHA256(surahsJson)}  '
      'assets/quran/surahs.json\n'
      '${ChecksumValidator.calculateSHA256(versesJson)}  '
      'assets/quran/verses.json\n';
}

class _StringAssetBundle extends CachingAssetBundle {
  final Map<String, String> assets;

  _StringAssetBundle(this.assets);

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) {
      throw StateError('Missing test asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}
