import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../../core/utils/checksum_validator.dart';
import '../../domain/models/surah.dart';
import '../../domain/models/verse.dart';
import '../local/entities/surah_entity.dart';
import '../local/entities/verse_entity.dart';
import '../local/isar_service.dart';
import 'quran_repository.dart';

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl();

  @override
  Future<void> loadQuranData() async {
    if (await isDataLoaded()) {
      return;
    }

    final isar = await IsarService.getInstance();

    await isar.writeTxn(() async {
      await isar.verseEntitys.clear();
      await isar.surahEntitys.clear();
    });

    final checksumLines =
        (await rootBundle.loadString('assets/quran/checksums.txt')).split('\n');

    await _loadSurahs(checksumLines);
    await _loadVerses(checksumLines);
  }

  Future<void> _loadSurahs(List<String> checksumLines) async {
    final surahsJson = await rootBundle.loadString('assets/quran/surahs.json');
    final expectedChecksum = checksumLines
        .firstWhere((line) => line.contains('surahs.json'), orElse: () => '')
        .split(' ')
        .first;

    if (expectedChecksum.isNotEmpty &&
        !ChecksumValidator.verify(surahsJson, expectedChecksum)) {
      throw Exception('Surahs data checksum verification failed');
    }

    final List<dynamic> surahsData = json.decode(surahsJson);
    final surahEntities = surahsData.map((data) {
      final surah = Surah(
        surahNumber: data['number'] as int,
        nameArabic: data['name'] as String,
        nameEnglish: data['translation'] as String,
        numberOfVerses: data['totalVerses'] as int,
      );
      return SurahEntity.fromDomain(surah);
    }).toList();

    final isar = await IsarService.getInstance();
    await isar.writeTxn(() async {
      await isar.surahEntitys.putAll(surahEntities);
    });
  }

  Future<void> _loadVerses(List<String> checksumLines) async {
    final versesJson = await rootBundle.loadString('assets/quran/verses.json');
    final expectedChecksum = checksumLines
        .firstWhere((line) => line.contains('verses.json'), orElse: () => '')
        .split(' ')
        .first;

    if (expectedChecksum.isNotEmpty &&
        !ChecksumValidator.verify(versesJson, expectedChecksum)) {
      throw Exception('Verses data checksum verification failed');
    }

    final List<dynamic> versesData = json.decode(versesJson);
    final verseEntities = versesData.map((data) {
      final verse = Verse(
        verseId: data['verseId'] as String,
        surahNumber: data['surahNumber'] as int,
        verseNumber: data['verseNumber'] as int,
        arabicText: data['arabicText'] as String,
        translation: data['translation'] as String?,
        page: data['page'] as int,
      );
      return VerseEntity.fromDomain(verse);
    }).toList();

    final isar = await IsarService.getInstance();

    const batchSize = 500;
    for (var i = 0; i < verseEntities.length; i += batchSize) {
      final end = (i + batchSize < verseEntities.length)
          ? i + batchSize
          : verseEntities.length;
      final batch = verseEntities.sublist(i, end);

      await isar.writeTxn(() async {
        await isar.verseEntitys.putAll(batch);
      });
    }
  }

  @override
  Future<List<Verse>> getVersesBySurah(int surahNumber) async {
    final isar = await IsarService.getInstance();

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

    final isar = await IsarService.getInstance();

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
    final isar = await IsarService.getInstance();

    final entity = await isar.verseEntitys
        .filter()
        .verseIdEqualTo(verseId)
        .findFirst();

    return entity?.toDomain();
  }

  @override
  Future<int> getPageForVerse(String verseId) async {
    final isar = await IsarService.getInstance();
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
    final isar = await IsarService.getInstance();
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
    final isar = await IsarService.getInstance();

    final entities = await isar.surahEntitys.where().findAll();

    entities.sort((a, b) => a.surahNumber.compareTo(b.surahNumber));
    return entities.map((e) => e.toDomain()).toList();
  }

  @override
  Future<Surah?> getSurahByNumber(int surahNumber) async {
    final isar = await IsarService.getInstance();

    final entity = await isar.surahEntitys.get(surahNumber);

    return entity?.toDomain();
  }

  @override
  Future<bool> isDataLoaded() async {
    final isar = await IsarService.getInstance();

    final verseCount = await isar.verseEntitys.count();
    final surahCount = await isar.surahEntitys.count();

    if (verseCount == 0 || surahCount != 114) return false;

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
