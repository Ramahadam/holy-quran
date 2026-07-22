import '../../domain/models/tafsir.dart';
import 'tafsir_repository.dart';
import 'tafsir_transport.dart';

class QuranFoundationTafsirRepository implements TafsirRepository {
  final TafsirTransport transport;

  const QuranFoundationTafsirRepository({required this.transport});

  @override
  Future<List<TafsirSource>> getSources() async {
    final response = await transport.invoke(const {'operation': 'sources'});
    final rawSources = response['sources'];
    if (rawSources is! List) {
      throw const TafsirException('The tafsir source list is invalid.');
    }

    try {
      return rawSources.map(_sourceFromJson).toList(growable: false);
    } on TafsirException {
      rethrow;
    } catch (error) {
      throw TafsirException('The tafsir source list is invalid.', error);
    }
  }

  @override
  Future<TafsirPassage> getTafsir({
    required String verseKey,
    required TafsirSource source,
  }) async {
    final response = await transport.invoke({
      'operation': 'ayah',
      'verseKey': verseKey,
      'resourceId': source.id,
    });
    final rawTafsir = response['tafsir'];
    if (rawTafsir is! Map) {
      throw const TafsirException('The tafsir response is invalid.');
    }

    final resourceId = rawTafsir['resourceId'];
    final rawText = rawTafsir['text'];
    if (resourceId != source.id || rawText is! String) {
      throw const TafsirException('The tafsir response is invalid.');
    }

    final text = _htmlToPlainText(rawText);
    if (text.isEmpty) {
      throw const TafsirException('No tafsir is available for this ayah.');
    }
    return TafsirPassage(source: source, text: text);
  }

  TafsirSource _sourceFromJson(Object? value) {
    if (value is! Map) {
      throw const TafsirException('A tafsir source is invalid.');
    }
    final id = value['id'];
    final name = value['name'];
    final authorName = value['authorName'];
    final languageName = value['languageName'];
    final slug = value['slug'];
    if (id is! int ||
        name is! String ||
        authorName is! String ||
        languageName is! String ||
        slug is! String ||
        id <= 0 ||
        name.trim().isEmpty ||
        languageName.trim().isEmpty) {
      throw const TafsirException('A tafsir source is invalid.');
    }
    return TafsirSource(
      id: id,
      name: name.trim(),
      authorName: authorName.trim(),
      languageName: languageName.trim(),
      slug: slug.trim(),
    );
  }
}

String _htmlToPlainText(String html) {
  var text = html
      .replaceAll(
        RegExp(
          r'<\s*(?:script|style)\b[^>]*>[\s\S]*?<\s*/\s*(?:script|style)\s*>',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(
          r'<\s*/?\s*(?:p|div|h[1-6]|li|blockquote|section|article)\s*>',
          caseSensitive: false,
        ),
        '\n',
      )
      .replaceAll(RegExp(r'<[^>]*>'), '');

  text = text.replaceAllMapped(RegExp(r'&#(?:x([0-9a-fA-F]+)|(\d+));'), (
    match,
  ) {
    final codePoint = int.tryParse(
      match.group(1) ?? match.group(2)!,
      radix: match.group(1) == null ? 10 : 16,
    );
    if (codePoint == null ||
        codePoint < 0 ||
        codePoint > 0x10ffff ||
        (codePoint >= 0xd800 && codePoint <= 0xdfff)) {
      return '';
    }
    return String.fromCharCode(codePoint);
  });

  const entities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&#39;': "'",
    '&nbsp;': ' ',
  };
  for (final entry in entities.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }

  return text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
}
