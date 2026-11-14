import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/tafsir/caching_tafsir_repository.dart';
import 'package:holy_quran_app/data/tafsir/tafsir_repository.dart';
import 'package:holy_quran_app/data/tafsir/tafsir_transport.dart';
import 'package:holy_quran_app/domain/models/tafsir.dart';

const _source = TafsirSource(
  id: 16,
  name: 'Tafsir Muyassar',
  authorName: 'Al-Muyassar',
  languageName: 'arabic',
  slug: 'ar-tafsir-muyassar',
);

void main() {
  late Directory directory;
  late _FakeTafsirRepository inner;
  late DateTime now;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('tafsir_cache_test');
    inner = _FakeTafsirRepository();
    now = DateTime(2026, 11, 1, 12);
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  CachingTafsirRepository repository({int maxBytes = 10 * 1024 * 1024}) =>
      CachingTafsirRepository(
        inner: inner,
        directory: () async => directory,
        clock: () => now,
        maxBytes: maxBytes,
      );

  group('CachingTafsirRepository', () {
    test('serves a revisited passage from the device', () async {
      final first = await repository().getTafsir(
        verseKey: '2:255',
        source: _source,
      );
      inner.failWith = const TafsirException('offline');

      final second = await repository().getTafsir(
        verseKey: '2:255',
        source: _source,
      );

      expect(second.text, first.text);
      expect(second.source, _source);
      expect(inner.tafsirCalls, 1);
    });

    test('refetches a passage once it is older than 7 days', () async {
      await repository().getTafsir(verseKey: '2:255', source: _source);
      now = now.add(const Duration(days: 7, minutes: 1));
      inner.text = 'updated';

      final passage = await repository().getTafsir(
        verseKey: '2:255',
        source: _source,
      );

      expect(passage.text, 'updated');
      expect(inner.tafsirCalls, 2);
    });

    test('deletes expired passages instead of serving them offline', () async {
      await repository().getTafsir(verseKey: '2:255', source: _source);
      now = now.add(const Duration(days: 8));
      inner.failWith = const TafsirException('offline');

      await expectLater(
        repository().getTafsir(verseKey: '2:255', source: _source),
        throwsA(isA<TafsirException>()),
      );
      expect(await _cachedFiles(directory), isEmpty);
    });

    test('does not cache failures', () async {
      inner.failWith = const TafsirException('offline');
      await expectLater(
        repository().getTafsir(verseKey: '2:255', source: _source),
        throwsA(isA<TafsirException>()),
      );
      inner.failWith = null;

      await repository().getTafsir(verseKey: '2:255', source: _source);

      expect(inner.tafsirCalls, 2);
    });

    test('evicts the oldest passages when over the size cap', () async {
      inner.text = 'x' * 400;
      final cache = repository(maxBytes: 1000);
      for (final verseKey in ['1:1', '1:2', '1:3']) {
        await cache.getTafsir(verseKey: verseKey, source: _source);
        now = now.add(const Duration(minutes: 1));
      }

      inner.failWith = const TafsirException('offline');
      await expectLater(
        cache.getTafsir(verseKey: '1:1', source: _source),
        throwsA(isA<TafsirException>()),
      );
      await cache.getTafsir(verseKey: '1:2', source: _source);
      await cache.getTafsir(verseKey: '1:3', source: _source);
      expect(await _cachedFiles(directory), hasLength(2));
    });

    test('serves the source list from the device for 7 days', () async {
      await repository().getSources();
      now = now.add(const Duration(days: 6));
      final cached = await repository().getSources();

      expect(cached, [_source]);
      expect(inner.sourcesCalls, 1);

      now = now.add(const Duration(days: 2));
      await repository().getSources();
      expect(inner.sourcesCalls, 2);
    });

    test('refetches when a cached file is corrupt', () async {
      await repository().getSources();
      for (final file in await _cachedFiles(directory)) {
        await file.writeAsString('{not json');
        await file.setLastModified(now);
      }

      final sources = await repository().getSources();

      expect(sources, [_source]);
      expect(inner.sourcesCalls, 2);
    });
  });
}

Future<List<File>> _cachedFiles(Directory directory) async =>
    directory.list().where((entity) => entity is File).cast<File>().toList();

class _FakeTafsirRepository implements TafsirRepository {
  String text = 'Allah - there is no deity except Him.';
  TafsirException? failWith;
  int tafsirCalls = 0;
  int sourcesCalls = 0;

  @override
  Future<List<TafsirSource>> getSources() async {
    sourcesCalls++;
    if (failWith case final error?) throw error;
    return const [_source];
  }

  @override
  Future<TafsirPassage> getTafsir({
    required String verseKey,
    required TafsirSource source,
  }) async {
    tafsirCalls++;
    if (failWith case final error?) throw error;
    return TafsirPassage(source: source, text: text);
  }
}
