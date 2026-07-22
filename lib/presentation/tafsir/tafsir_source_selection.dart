import '../../domain/models/tafsir.dart';

const _preferredArabicSourceId = 16;
const _preferredEnglishSourceId = 169;

TafsirSource selectTafsirSource(
  List<TafsirSource> sources,
  String appLanguageCode, {
  int? selectedSourceId,
}) {
  if (sources.isEmpty) {
    throw ArgumentError.value(sources, 'sources', 'Must not be empty.');
  }

  if (selectedSourceId != null) {
    for (final source in sources) {
      if (source.id == selectedSourceId) return source;
    }
  }

  final preferredSourceId = appLanguageCode.toLowerCase() == 'ar'
      ? _preferredArabicSourceId
      : _preferredEnglishSourceId;
  for (final source in sources) {
    if (source.id == preferredSourceId) return source;
  }

  final desiredLanguage = _tafsirLanguageFor(appLanguageCode);
  for (final source in sources) {
    if (source.languageName.toLowerCase() == desiredLanguage) return source;
  }
  return sources.first;
}

List<TafsirSource> tafsirSourcesForLanguage(
  List<TafsirSource> sources,
  String appLanguageCode,
) {
  final desiredLanguage = _tafsirLanguageFor(appLanguageCode);
  final matchingSources = sources
      .where((source) => source.languageName.toLowerCase() == desiredLanguage)
      .toList(growable: false);
  return matchingSources.isEmpty ? sources : matchingSources;
}

String tafsirSourceNameForLanguage(
  TafsirSource source,
  String appLanguageCode,
) {
  if (appLanguageCode.toLowerCase() != 'ar') return source.name;

  return switch (source.id) {
    926 => 'تفسير الجلالين',
    925 => 'التحرير والتنوير',
    94 => 'تفسير البغوي',
    15 => 'تفسير الطبري',
    93 => 'التفسير الوسيط',
    90 => 'تفسير القرطبي',
    14 => 'تفسير ابن كثير',
    16 => 'التفسير الميسر',
    91 => 'تفسير السعدي',
    _ => source.name,
  };
}

String tafsirAuthorNameForLanguage(
  TafsirSource source,
  String appLanguageCode,
) {
  if (appLanguageCode.toLowerCase() != 'ar') return source.authorName;

  return switch (source.id) {
    926 => 'جلال الدين المحلي وجلال الدين السيوطي',
    925 => 'محمد الطاهر بن عاشور',
    94 => 'الإمام البغوي',
    15 => 'الإمام الطبري',
    93 => 'محمد سيد طنطاوي',
    90 => 'الإمام القرطبي',
    14 => 'الحافظ ابن كثير',
    16 => 'نخبة من العلماء',
    91 => 'عبد الرحمن السعدي',
    _ => source.authorName,
  };
}

String _tafsirLanguageFor(String appLanguageCode) {
  return appLanguageCode.toLowerCase() == 'ar' ? 'arabic' : 'english';
}
