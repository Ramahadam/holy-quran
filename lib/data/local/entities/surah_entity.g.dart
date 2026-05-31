// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'surah_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSurahEntityCollection on Isar {
  IsarCollection<SurahEntity> get surahEntitys => this.collection();
}

final SurahEntitySchema = CollectionSchema(
  name: r'SurahEntity',
  id: int.parse('1957003966686490940'),
  properties: {
    r'nameArabic': PropertySchema(
      id: 0,
      name: r'nameArabic',
      type: IsarType.string,
    ),
    r'nameEnglish': PropertySchema(
      id: 1,
      name: r'nameEnglish',
      type: IsarType.string,
    ),
    r'numberOfVerses': PropertySchema(
      id: 2,
      name: r'numberOfVerses',
      type: IsarType.long,
    ),
    r'surahNumber': PropertySchema(
      id: 3,
      name: r'surahNumber',
      type: IsarType.long,
    )
  },
  estimateSize: _surahEntityEstimateSize,
  serialize: _surahEntitySerialize,
  deserialize: _surahEntityDeserialize,
  deserializeProp: _surahEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _surahEntityGetId,
  getLinks: _surahEntityGetLinks,
  attach: _surahEntityAttach,
  version: '3.1.0+1',
);

int _surahEntityEstimateSize(
  SurahEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.nameArabic.length * 3;
  bytesCount += 3 + object.nameEnglish.length * 3;
  return bytesCount;
}

void _surahEntitySerialize(
  SurahEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.nameArabic);
  writer.writeString(offsets[1], object.nameEnglish);
  writer.writeLong(offsets[2], object.numberOfVerses);
  writer.writeLong(offsets[3], object.surahNumber);
}

SurahEntity _surahEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SurahEntity();
  object.nameArabic = reader.readString(offsets[0]);
  object.nameEnglish = reader.readString(offsets[1]);
  object.numberOfVerses = reader.readLong(offsets[2]);
  object.surahNumber = reader.readLong(offsets[3]);
  return object;
}

P _surahEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _surahEntityGetId(SurahEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _surahEntityGetLinks(SurahEntity object) {
  return [];
}

void _surahEntityAttach(
    IsarCollection<dynamic> col, Id id, SurahEntity object) {}

extension SurahEntityQueryWhereSort
    on QueryBuilder<SurahEntity, SurahEntity, QWhere> {
  QueryBuilder<SurahEntity, SurahEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SurahEntityQueryWhere
    on QueryBuilder<SurahEntity, SurahEntity, QWhereClause> {
  QueryBuilder<SurahEntity, SurahEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterWhereClause> idBetween(
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

extension SurahEntityQueryFilter
    on QueryBuilder<SurahEntity, SurahEntity, QFilterCondition> {
  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameArabicEqualTo(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameArabicGreaterThan(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameArabicLessThan(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameArabicBetween(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameArabicStartsWith(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameArabicEndsWith(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameArabicContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameArabic',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameArabicMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameArabic',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameArabicIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameArabic',
        value: '',
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameArabicIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameArabic',
        value: '',
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameEnglishEqualTo(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameEnglishGreaterThan(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameEnglishLessThan(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameEnglishBetween(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameEnglishStartsWith(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameEnglishEndsWith(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameEnglishContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameEnglish',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameEnglishMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameEnglish',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameEnglishIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEnglish',
        value: '',
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      nameEnglishIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameEnglish',
        value: '',
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      numberOfVersesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numberOfVerses',
        value: value,
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      numberOfVersesGreaterThan(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      numberOfVersesLessThan(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      numberOfVersesBetween(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      surahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      surahNumberGreaterThan(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      surahNumberLessThan(
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

  QueryBuilder<SurahEntity, SurahEntity, QAfterFilterCondition>
      surahNumberBetween(
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

extension SurahEntityQueryObject
    on QueryBuilder<SurahEntity, SurahEntity, QFilterCondition> {}

extension SurahEntityQueryLinks
    on QueryBuilder<SurahEntity, SurahEntity, QFilterCondition> {}

extension SurahEntityQuerySortBy
    on QueryBuilder<SurahEntity, SurahEntity, QSortBy> {
  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> sortByNameArabic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.asc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> sortByNameArabicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.desc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> sortByNameEnglish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.asc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> sortByNameEnglishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.desc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> sortByNumberOfVerses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfVerses', Sort.asc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy>
      sortByNumberOfVersesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfVerses', Sort.desc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> sortBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.asc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> sortBySurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.desc);
    });
  }
}

extension SurahEntityQuerySortThenBy
    on QueryBuilder<SurahEntity, SurahEntity, QSortThenBy> {
  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> thenByNameArabic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.asc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> thenByNameArabicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameArabic', Sort.desc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> thenByNameEnglish() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.asc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> thenByNameEnglishDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEnglish', Sort.desc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> thenByNumberOfVerses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfVerses', Sort.asc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy>
      thenByNumberOfVersesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberOfVerses', Sort.desc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> thenBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.asc);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QAfterSortBy> thenBySurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.desc);
    });
  }
}

extension SurahEntityQueryWhereDistinct
    on QueryBuilder<SurahEntity, SurahEntity, QDistinct> {
  QueryBuilder<SurahEntity, SurahEntity, QDistinct> distinctByNameArabic(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameArabic', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QDistinct> distinctByNameEnglish(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameEnglish', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QDistinct> distinctByNumberOfVerses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numberOfVerses');
    });
  }

  QueryBuilder<SurahEntity, SurahEntity, QDistinct> distinctBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahNumber');
    });
  }
}

extension SurahEntityQueryProperty
    on QueryBuilder<SurahEntity, SurahEntity, QQueryProperty> {
  QueryBuilder<SurahEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SurahEntity, String, QQueryOperations> nameArabicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameArabic');
    });
  }

  QueryBuilder<SurahEntity, String, QQueryOperations> nameEnglishProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameEnglish');
    });
  }

  QueryBuilder<SurahEntity, int, QQueryOperations> numberOfVersesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numberOfVerses');
    });
  }

  QueryBuilder<SurahEntity, int, QQueryOperations> surahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahNumber');
    });
  }
}
