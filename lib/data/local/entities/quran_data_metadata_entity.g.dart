// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quran_data_metadata_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetQuranDataMetadataEntityCollection on Isar {
  IsarCollection<QuranDataMetadataEntity> get quranDataMetadataEntitys =>
      this.collection();
}

const QuranDataMetadataEntitySchema = CollectionSchema(
  name: r'QuranDataMetadataEntity',
  id: 6185202444373853269,
  properties: {
    r'contentDigest': PropertySchema(
      id: 0,
      name: r'contentDigest',
      type: IsarType.string,
    ),
    r'surahCount': PropertySchema(
      id: 1,
      name: r'surahCount',
      type: IsarType.long,
    ),
    r'verseCount': PropertySchema(
      id: 2,
      name: r'verseCount',
      type: IsarType.long,
    )
  },
  estimateSize: _quranDataMetadataEntityEstimateSize,
  serialize: _quranDataMetadataEntitySerialize,
  deserialize: _quranDataMetadataEntityDeserialize,
  deserializeProp: _quranDataMetadataEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _quranDataMetadataEntityGetId,
  getLinks: _quranDataMetadataEntityGetLinks,
  attach: _quranDataMetadataEntityAttach,
  version: '3.1.0+1',
);

int _quranDataMetadataEntityEstimateSize(
  QuranDataMetadataEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contentDigest.length * 3;
  return bytesCount;
}

void _quranDataMetadataEntitySerialize(
  QuranDataMetadataEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.contentDigest);
  writer.writeLong(offsets[1], object.surahCount);
  writer.writeLong(offsets[2], object.verseCount);
}

QuranDataMetadataEntity _quranDataMetadataEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = QuranDataMetadataEntity();
  object.contentDigest = reader.readString(offsets[0]);
  object.id = id;
  object.surahCount = reader.readLong(offsets[1]);
  object.verseCount = reader.readLong(offsets[2]);
  return object;
}

P _quranDataMetadataEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _quranDataMetadataEntityGetId(QuranDataMetadataEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _quranDataMetadataEntityGetLinks(
    QuranDataMetadataEntity object) {
  return [];
}

void _quranDataMetadataEntityAttach(
    IsarCollection<dynamic> col, Id id, QuranDataMetadataEntity object) {
  object.id = id;
}

extension QuranDataMetadataEntityQueryWhereSort
    on QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QWhere> {
  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension QuranDataMetadataEntityQueryWhere on QueryBuilder<
    QuranDataMetadataEntity, QuranDataMetadataEntity, QWhereClause> {
  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterWhereClause> idBetween(
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

extension QuranDataMetadataEntityQueryFilter on QueryBuilder<
    QuranDataMetadataEntity, QuranDataMetadataEntity, QFilterCondition> {
  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> contentDigestEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contentDigest',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> contentDigestGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contentDigest',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> contentDigestLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contentDigest',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> contentDigestBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contentDigest',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> contentDigestStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contentDigest',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> contentDigestEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contentDigest',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
          QAfterFilterCondition>
      contentDigestContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contentDigest',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
          QAfterFilterCondition>
      contentDigestMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contentDigest',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> contentDigestIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contentDigest',
        value: '',
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> contentDigestIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contentDigest',
        value: '',
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> surahCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahCount',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> surahCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'surahCount',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> surahCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'surahCount',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> surahCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'surahCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> verseCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verseCount',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> verseCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'verseCount',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> verseCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'verseCount',
        value: value,
      ));
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity,
      QAfterFilterCondition> verseCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'verseCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension QuranDataMetadataEntityQueryObject on QueryBuilder<
    QuranDataMetadataEntity, QuranDataMetadataEntity, QFilterCondition> {}

extension QuranDataMetadataEntityQueryLinks on QueryBuilder<
    QuranDataMetadataEntity, QuranDataMetadataEntity, QFilterCondition> {}

extension QuranDataMetadataEntityQuerySortBy
    on QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QSortBy> {
  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      sortByContentDigest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentDigest', Sort.asc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      sortByContentDigestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentDigest', Sort.desc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      sortBySurahCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahCount', Sort.asc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      sortBySurahCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahCount', Sort.desc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      sortByVerseCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseCount', Sort.asc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      sortByVerseCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseCount', Sort.desc);
    });
  }
}

extension QuranDataMetadataEntityQuerySortThenBy on QueryBuilder<
    QuranDataMetadataEntity, QuranDataMetadataEntity, QSortThenBy> {
  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      thenByContentDigest() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentDigest', Sort.asc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      thenByContentDigestDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentDigest', Sort.desc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      thenBySurahCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahCount', Sort.asc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      thenBySurahCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahCount', Sort.desc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      thenByVerseCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseCount', Sort.asc);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QAfterSortBy>
      thenByVerseCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseCount', Sort.desc);
    });
  }
}

extension QuranDataMetadataEntityQueryWhereDistinct on QueryBuilder<
    QuranDataMetadataEntity, QuranDataMetadataEntity, QDistinct> {
  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QDistinct>
      distinctByContentDigest({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentDigest',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QDistinct>
      distinctBySurahCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahCount');
    });
  }

  QueryBuilder<QuranDataMetadataEntity, QuranDataMetadataEntity, QDistinct>
      distinctByVerseCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verseCount');
    });
  }
}

extension QuranDataMetadataEntityQueryProperty on QueryBuilder<
    QuranDataMetadataEntity, QuranDataMetadataEntity, QQueryProperty> {
  QueryBuilder<QuranDataMetadataEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<QuranDataMetadataEntity, String, QQueryOperations>
      contentDigestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentDigest');
    });
  }

  QueryBuilder<QuranDataMetadataEntity, int, QQueryOperations>
      surahCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahCount');
    });
  }

  QueryBuilder<QuranDataMetadataEntity, int, QQueryOperations>
      verseCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verseCount');
    });
  }
}
