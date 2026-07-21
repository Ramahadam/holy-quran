import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/data/tafsir/quran_foundation_tafsir_repository.dart';
import 'package:holy_quran_app/data/tafsir/tafsir_transport.dart';

void main() {
  group('QuranFoundationTafsirRepository', () {
    test('maps English and Arabic source metadata', () async {
      final transport = _FakeTafsirTransport({
        'sources': [
          {
            'id': 169,
            'name': 'Tafsir Ibn Kathir',
            'authorName': 'Hafiz Ibn Kathir',
            'languageName': 'english',
            'slug': 'en-tafsir-ibn-kathir',
          },
          {
            'id': 16,
            'name': 'Tafsir al-Tabari',
            'authorName': 'Imam al-Tabari',
            'languageName': 'arabic',
            'slug': 'tafsir-tabari',
          },
        ],
      });
      final repository = QuranFoundationTafsirRepository(transport: transport);

      final sources = await repository.getSources();

      expect(sources, hasLength(2));
      expect(sources.first.id, 169);
      expect(sources.first.authorName, 'Hafiz Ibn Kathir');
      expect(sources.last.isArabic, isTrue);
      expect(transport.lastBody, {'operation': 'sources'});
    });

    test('turns upstream HTML into safe readable text', () async {
      final transport = _FakeTafsirTransport({
        'tafsir': {
          'resourceId': 169,
          'text':
              '<h2>Meaning</h2><p>Allah &amp; His messenger.</p>'
              '<script>unsafe()</script><p>&#x627;&#1604;&#1604;&#1607;</p>',
        },
      });
      final repository = QuranFoundationTafsirRepository(transport: transport);
      final source = (await QuranFoundationTafsirRepository(
        transport: _FakeTafsirTransport({
          'sources': [
            {
              'id': 169,
              'name': 'Tafsir Ibn Kathir',
              'authorName': 'Hafiz Ibn Kathir',
              'languageName': 'english',
              'slug': 'en-tafsir-ibn-kathir',
            },
          ],
        }),
      ).getSources()).single;

      final passage = await repository.getTafsir(
        verseKey: '1:1',
        source: source,
      );

      expect(passage.text, 'Meaning\nAllah & His messenger.\nالله');
      expect(passage.source, source);
      expect(transport.lastBody, {
        'operation': 'ayah',
        'verseKey': '1:1',
        'resourceId': 169,
      });
    });

    test('rejects malformed source data', () async {
      final repository = QuranFoundationTafsirRepository(
        transport: _FakeTafsirTransport({
          'sources': [
            {'id': '169'},
          ],
        }),
      );

      await expectLater(
        repository.getSources(),
        throwsA(isA<TafsirException>()),
      );
    });

    test('rejects a response for a different resource', () async {
      final sourceRepository = QuranFoundationTafsirRepository(
        transport: _FakeTafsirTransport({
          'sources': [
            {
              'id': 169,
              'name': 'Tafsir Ibn Kathir',
              'authorName': 'Hafiz Ibn Kathir',
              'languageName': 'english',
              'slug': 'en-tafsir-ibn-kathir',
            },
          ],
        }),
      );
      final source = (await sourceRepository.getSources()).single;
      final repository = QuranFoundationTafsirRepository(
        transport: _FakeTafsirTransport({
          'tafsir': {'resourceId': 16, 'text': 'Wrong resource'},
        }),
      );

      await expectLater(
        repository.getTafsir(verseKey: '1:1', source: source),
        throwsA(isA<TafsirException>()),
      );
    });
  });
}

class _FakeTafsirTransport implements TafsirTransport {
  final Map<String, dynamic> response;
  Map<String, dynamic>? lastBody;

  _FakeTafsirTransport(this.response);

  @override
  Future<Map<String, dynamic>> invoke(Map<String, dynamic> body) async {
    lastBody = body;
    return response;
  }
}
