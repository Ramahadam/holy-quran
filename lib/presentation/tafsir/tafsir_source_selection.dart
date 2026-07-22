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

List<TafsirSource> orderTafsirSourcesForLanguage(
  List<TafsirSource> sources,
  String appLanguageCode,
) {
  final desiredLanguage = _tafsirLanguageFor(appLanguageCode);
  return [
    ...sources.where(
      (source) => source.languageName.toLowerCase() == desiredLanguage,
    ),
    ...sources.where(
      (source) => source.languageName.toLowerCase() != desiredLanguage,
    ),
  ];
}

String _tafsirLanguageFor(String appLanguageCode) {
  return appLanguageCode.toLowerCase() == 'ar' ? 'arabic' : 'english';
}
