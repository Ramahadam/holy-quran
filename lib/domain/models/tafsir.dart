class TafsirSource {
  final int id;
  final String name;
  final String authorName;
  final String languageName;
  final String slug;

  const TafsirSource({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
    required this.slug,
  });

  bool get isArabic => languageName.toLowerCase() == 'arabic';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TafsirSource &&
          id == other.id &&
          name == other.name &&
          authorName == other.authorName &&
          languageName == other.languageName &&
          slug == other.slug;

  @override
  int get hashCode => Object.hash(id, name, authorName, languageName, slug);
}

class TafsirPassage {
  final TafsirSource source;
  final String text;

  const TafsirPassage({required this.source, required this.text});
}
