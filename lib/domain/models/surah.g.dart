// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surah.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSurahCollection on Isar {
  IsarCollection<Surah> get surahs => this.collection();
}

const SurahSchema = CollectionSchema(
  name: r'Surah',
  id: -5819800798527960797,
  properties: {
    r'hashCode': PropertySchema(
      id: 0,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'nameArabic': PropertySchema(
      id: 1,
      name: r'nameArabic',
      type: IsarType.string,
    ),
    r'nameEnglish': PropertySchema(
      id: 2,
      name: r'nameEnglish',
      type: IsarType.string,
    ),
    r'numberOfVerses': PropertySchema(
      id: 3,
      name: r'numberOfVerses',
      type: IsarType.long,
    ),
    r'surahNumber': PropertySchema(
      id: 4,
      name: r'surahNumber',
      type: IsarType.long,
    )
  },
  estimateSize: _surahEstimateSize,
  serialize: _surahSerialize,
  deserialize: _surahDeserialize,
  deserializeProp: _surahDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _surahGetId,
  getLinks: _surahGetLinks,
  attach: _surahAttach,
  version: '3.1.0+1',
);

int _surahEstimateSize(
  Surah object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.nameArabic.length * 3;
  bytesCount += 3 + object.nameEnglish.length * 3;
  return bytesCount;
}

void _surahSerialize(
  Surah object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.hashCode);
  writer.writeString(offsets[1], object.nameArabic);
  writer.writeString(offsets[2], object.nameEnglish);
  writer.writeLong(offsets[3], object.numberOfVerses);
  writer.writeLong(offsets[4], object.surahNumber);
}

Surah _surahDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Surah(
    nameArabic: reader.readString(offsets[1]),
    nameEnglish: reader.readString(offsets[2]),
    numberOfVerses: reader.readLong(offsets[3]),
    surahNumber: reader.readLong(offsets[4]),
  );
  return object;
}

P _surahDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _surahGetId(Surah object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _surahGetLinks(Surah object) {
  return [];
}

void _surahAttach(IsarCollection<dynamic> col, Id id, Surah object) {}

extension SurahQueryWhereSort on QueryBuilder<Surah, Surah, QWhere> {
  QueryBuilder<Surah, Surah, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SurahQueryWhere on QueryBuilder<Surah, Surah, QWhereClause> {
  QueryBuilder<Surah, Surah, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Surah, Surah, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SurahQueryFilter on QueryBuilder<Surah, Surah, QFilterCondition> {
  QueryBuilder<Surah, Surah, QAfterFilterCondition> hashCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameArabic',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameArabic',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameArabic',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameArabicIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameArabic',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameEnglish',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameEnglish',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEnglish',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> nameEnglishIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameEnglish',
        value: '',
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberOfVersesEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numberOfVerses',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberOfVersesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numberOfVerses',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberOfVersesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numberOfVerses',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> numberOfVersesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numberOfVerses',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> surahNumberEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> surahNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'surahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> surahNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'surahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Surah, Surah, QAfterFilterCondition> surahNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'surahNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SurahQueryObject on QueryBuilder<Surah, Surah, QFilterCondition> {}

extension SurahQueryLinks on QueryBuilder<Surah, Surah, QFilterCondition> {}

extension SurahQuerySortBy on QueryBuilder<Surah, Surah, QSortBy> {
  QueryBuilder<Surah, Surah, QAfterSortBy> sortByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNameArabic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNameArabicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNameEnglish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNameEnglishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNumberOfVerses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfVerses', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortByNumberOfVersesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfVerses', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> sortBySurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.desc);
    });
  }
}

extension SurahQuerySortThenBy on QueryBuilder<Surah, Surah, QSortThenBy> {
  QueryBuilder<Surah, Surah, QAfterSortBy> thenByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNameArabic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNameArabicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNameEnglish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNameEnglishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNumberOfVerses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfVerses', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenByNumberOfVersesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfVerses', Sort.desc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.asc);
    });
  }

  QueryBuilder<Surah, Surah, QAfterSortBy> thenBySurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.desc);
    });
  }
}

extension SurahQueryWhereDistinct on QueryBuilder<Surah, Surah, QDistinct> {
  QueryBuilder<Surah, Surah, QDistinct> distinctByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hashCode');
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByNameArabic(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameArabic', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByNameEnglish(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameEnglish', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctByNumberOfVerses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numberOfVerses');
    });
  }

  QueryBuilder<Surah, Surah, QDistinct> distinctBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahNumber');
    });
  }
}

extension SurahQueryProperty on QueryBuilder<Surah, Surah, QQueryProperty> {
  QueryBuilder<Surah, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Surah, int, QQueryOperations> hashCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashCode');
    });
  }

  QueryBuilder<Surah, String, QQueryOperations> nameArabicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameArabic');
    });
  }

  QueryBuilder<Surah, String, QQueryOperations> nameEnglishProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameEnglish');
    });
  }

  QueryBuilder<Surah, int, QQueryOperations> numberOfVersesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numberOfVerses');
    });
  }

  QueryBuilder<Surah, int, QQueryOperations> surahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahNumber');
    });
  }
}
