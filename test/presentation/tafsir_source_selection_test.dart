import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/domain/models/tafsir.dart';
import 'package:holy_quran_app/presentation/tafsir/tafsir_source_selection.dart';

void main() {
  test('selects Muyassar for Arabic and Ibn Kathir for English', () {
    expect(selectTafsirSource(_sources, 'ar').id, 16);
    expect(selectTafsirSource(_sources, 'en').id, 169);
  });

  test('keeps an explicit source selection across app languages', () {
    expect(selectTafsirSource(_sources, 'ar', selectedSourceId: 15).id, 15);
    expect(selectTafsirSource(_sources, 'en', selectedSourceId: 15).id, 15);
  });

  test('falls back to the first source in the app language', () {
    final sourcesWithoutMuyassar = _sources
        .where((source) => source.id != 16)
        .toList();

    expect(selectTafsirSource(sourcesWithoutMuyassar, 'ar').id, 15);
  });

  test('shows only sources matching the app language', () {
    expect(
      tafsirSourcesForLanguage(_sources, 'ar').map((source) => source.id),
      [16, 15],
    );
    expect(
      tafsirSourcesForLanguage(_sources, 'en').map((source) => source.id),
      [169, 168],
    );
  });

  test('localizes known Arabic source names and authors', () {
    expect(tafsirSourceNameForLanguage(_sources[1], 'ar'), 'التفسير الميسر');
    expect(tafsirAuthorNameForLanguage(_sources[1], 'ar'), 'نخبة من العلماء');
    expect(tafsirSourceNameForLanguage(_sources[2], 'ar'), 'تفسير الطبري');
    expect(tafsirAuthorNameForLanguage(_sources[2], 'ar'), 'الإمام الطبري');
    expect(
      tafsirSourceNameForLanguage(_sources.first, 'en'),
      'Ibn Kathir (Abridged)',
    );
  });
}

const _sources = [
  TafsirSource(
    id: 169,
    name: 'Ibn Kathir (Abridged)',
    authorName: 'Hafiz Ibn Kathir',
    languageName: 'english',
    slug: 'en-tafsir-ibn-kathir',
  ),
  TafsirSource(
    id: 16,
    name: 'Tafsir Muyassar',
    authorName: 'الميسر',
    languageName: 'arabic',
    slug: 'ar-tafsir-muyassar',
  ),
  TafsirSource(
    id: 15,
    name: 'Tafsir al-Tabari',
    authorName: 'Tabari',
    languageName: 'arabic',
    slug: 'ar-tafsir-al-tabari',
  ),
  TafsirSource(
    id: 168,
    name: "Ma'arif al-Qur'an",
    authorName: 'Mufti Muhammad Shafi',
    languageName: 'english',
    slug: 'en-tafsir-maarif-ul-quran',
  ),
];
