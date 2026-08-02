import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../../core/utils/checksum_validator.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/verse.dart';
import '../local/entities/quran_data_metadata_entity.dart';
import '../local/entities/surah_entity.dart';
import '../local/entities/verse_entity.dart';
import '../local/isar_service.dart';
import 'quran_repository.dart';

const _checksumsAsset = 'assets/quran/checksums.txt';
const _surahsAsset = 'assets/quran/surahs.json';
const _versesAsset = 'assets/quran/verses.json';
const _canonicalSurahCount = 114;
const _canonicalVerseCount = 6236;

class QuranRepositoryImpl implements QuranRepository {
  final AssetBundle _assetBundle;
  final Future<Isar> Function() _getDatabase;

  QuranRepositoryImpl({
    AssetBundle? assetBundle,
    Future<Isar> Function()? getDatabase,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _getDatabase = getDatabase ?? IsarService.getInstance;

  @override
  Future<void> loadQuranData() async {
    final manifest = await _readManifest();
    final isar = await _getDatabase();
    if (await _isDataLoaded(isar, manifest.digest)) return;

    final content = await _readAndValidateContent(manifest);

    await isar.writeTxn(() async {
      await isar.verseEntitys.clear();
      await isar.surahEntitys.clear();
      await isar.quranDataMetadataEntitys.clear();
      await isar.surahEntitys.putAll(content.surahs);
      await isar.verseEntitys.putAll(content.verses);
      await isar.quranDataMetadataEntitys.put(
        QuranDataMetadataEntity.installed(
          contentDigest: manifest.digest,
          surahCount: content.surahs.length,
          verseCount: content.verses.length,
        ),
      );
    });
  }

  Future<({String digest, String surahsChecksum, String versesChecksum})>
  _readManifest() async {
    final manifest = await _assetBundle.loadString(_checksumsAsset);
    final checksums = <String, String>{};
    for (final match in RegExp(
      r'^([a-fA-F0-9]{64})\s+(.+)$',
      multiLine: true,
    ).allMatches(manifest)) {
      checksums[match.group(2)!.trim()] = match.group(1)!.toLowerCase();
    }

    final surahsChecksum = checksums[_surahsAsset];
    final versesChecksum = checksums[_versesAsset];
    if (surahsChecksum == null || versesChecksum == null) {
      throw const FormatException(
        'Quran checksum manifest is missing required assets.',
      );
    }

    return (
      digest: ChecksumValidator.calculateSHA256(
        '$surahsChecksum\n$versesChecksum',
      ),
      surahsChecksum: surahsChecksum,
      versesChecksum: versesChecksum,
    );
  }

  Future<({List<SurahEntity> surahs, List<VerseEntity> verses})>
  _readAndValidateContent(
    ({String digest, String surahsChecksum, String versesChecksum}) manifest,
  ) async {
    final assets = await Future.wait([
      _assetBundle.loadString(_surahsAsset),
      _assetBundle.loadString(_versesAsset),
    ]);
    final surahsJson = assets[0];
    final versesJson = assets[1];

    if (!ChecksumValidator.verify(surahsJson, manifest.surahsChecksum)) {
      throw const FormatException('Surahs data checksum verification failed.');
    }
    if (!ChecksumValidator.verify(versesJson, manifest.versesChecksum)) {
      throw const FormatException('Verses data checksum verification failed.');
    }

    return (surahs: _parseSurahs(surahsJson), verses: _parseVerses(versesJson));
  }

  List<SurahEntity> _parseSurahs(String input) {
    try {
      final decoded = jsonDecode(input);
      if (decoded is! List) throw const FormatException();
      final entities = decoded
          .map((value) {
            final data = (value as Map).cast<String, Object?>();
            return SurahEntity.fromDomain(
              Surah(
                surahNumber: data['number'] as int,
                nameArabic: data['name'] as String,
                nameEnglish: data['translation'] as String,
                numberOfVerses: data['totalVerses'] as int,
              ),
            );
          })
          .toList(growable: false);
      if (entities.length != _canonicalSurahCount) {
        throw const FormatException();
      }
      return entities;
    } catch (error) {
      if (error is FormatException && error.message.isNotEmpty) rethrow;
      throw const FormatException('Surahs data is invalid.');
    }
  }

  List<VerseEntity> _parseVerses(String input) {
    try {
      final decoded = jsonDecode(input);
      if (decoded is! List) throw const FormatException();
      final entities = decoded
          .map((value) {
            final data = (value as Map).cast<String, Object?>();
            return VerseEntity.fromDomain(
              Verse(
                verseId: data['verseId'] as String,
                surahNumber: data['surahNumber'] as int,
                verseNumber: data['verseNumber'] as int,
                arabicText: data['arabicText'] as String,
                translation: data['translation'] as String?,
                page: data['page'] as int,
              ),
            );
          })
          .toList(growable: false);
      if (entities.length != _canonicalVerseCount) {
        throw const FormatException();
      }
      return entities;
    } catch (error) {
      if (error is FormatException && error.message.isNotEmpty) rethrow;
      throw const FormatException('Verses data is invalid.');
    }
  }

  @override
  Future<List<Verse>> getVersesBySurah(int surahNumber) async {
    final isar = await _getDatabase();

    final entities = await isar.verseEntitys
        .filter()
        .surahNumberEqualTo(surahNumber)
        .sortByVerseNumber()
        .findAll();

    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Verse>> getVersesByPage(int page) async {
    if (page < 1 || page > 604) {
      throw ArgumentError('Page must be between 1 and 604, got $page');
    }

    final isar = await _getDatabase();

    final entities = await isar.verseEntitys
        .where()
        .pageEqualTo(page)
        .findAll();

    // Sort by surah then verse for pages that span surahs.
    entities.sort((a, b) {
      final cmp = a.surahNumber.compareTo(b.surahNumber);
      return cmp != 0 ? cmp : a.verseNumber.compareTo(b.verseNumber);
    });

    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<Verse?> getVerseById(String verseId) async {
    final isar = await _getDatabase();

    final entity = await isar.verseEntitys
        .filter()
        .verseIdEqualTo(verseId)
        .findFirst();

    return entity?.toDomain();
  }

  @override
  Future<int> getPageForVerse(String verseId) async {
    final isar = await _getDatabase();
    final entity = await isar.verseEntitys
        .filter()
        .verseIdEqualTo(verseId)
        .findFirst();
    if (entity == null) {
      throw StateError('Verse not found: $verseId');
    }
    return entity.page;
  }

  @override
  Future<int> getStartPageForSurah(int surahNumber) async {
    final isar = await _getDatabase();
    final entity = await isar.verseEntitys
        .filter()
        .surahNumberEqualTo(surahNumber)
        .sortByPage()
        .findFirst();
    if (entity == null) {
      throw StateError('Surah not found: $surahNumber');
    }
    return entity.page;
  }

  @override
  Future<List<Surah>> getAllSurahs() async {
    final isar = await _getDatabase();

    final entities = await isar.surahEntitys.where().findAll();

    entities.sort((a, b) => a.surahNumber.compareTo(b.surahNumber));
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<Surah?> getSurahByNumber(int surahNumber) async {
    final isar = await _getDatabase();

    final entity = await isar.surahEntitys.get(surahNumber);

    return entity?.toDomain();
  }

  @override
  Future<bool> isDataLoaded() async {
    final manifest = await _readManifest();
    final isar = await _getDatabase();
    return _isDataLoaded(isar, manifest.digest);
  }

  Future<bool> _isDataLoaded(Isar isar, String expectedDigest) async {
    final metadata = await isar.quranDataMetadataEntitys.get(
      QuranDataMetadataEntity.singletonId,
    );
    if (metadata == null || metadata.contentDigest != expectedDigest) {
      return false;
    }

    final verseCount = await isar.verseEntitys.count();
    final surahCount = await isar.surahEntitys.count();

    if (verseCount != metadata.verseCount ||
        surahCount != metadata.surahCount ||
        verseCount != _canonicalVerseCount ||
        surahCount != _canonicalSurahCount) {
      return false;
    }

    // Check if page data is present (migration from pre-page schema).
    final sample = await isar.verseEntitys.where().findFirst();
    if (sample != null && sample.page == 0) return false;

    // Verify that page queries work across the full range (check first and last page).
    final page1Verses = await isar.verseEntitys
        .where()
        .pageEqualTo(1)
        .findAll();
    if (page1Verses.isEmpty) return false;

    final page604Verses = await isar.verseEntitys
        .where()
        .pageEqualTo(604)
        .findAll();
    if (page604Verses.isEmpty) return false;

    return true;
  }
}
