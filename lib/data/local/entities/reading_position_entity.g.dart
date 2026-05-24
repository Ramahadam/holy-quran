// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_position_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReadingPositionEntityCollection on Isar {
  IsarCollection<ReadingPositionEntity> get readingPositionEntitys =>
      this.collection();
}

const ReadingPositionEntitySchema = CollectionSchema(
  name: r'ReadingPositionEntity',
  id: 8410079443906433630,
  properties: {
    r'lastReadAt': PropertySchema(
      id: 0,
      name: r'lastReadAt',
      type: IsarType.dateTime,
    ),
    r'verseId': PropertySchema(
      id: 1,
      name: r'verseId',
      type: IsarType.string,
    )
  },
  estimateSize: _readingPositionEntityEstimateSize,
  serialize: _readingPositionEntitySerialize,
  deserialize: _readingPositionEntityDeserialize,
  deserializeProp: _readingPositionEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _readingPositionEntityGetId,
  getLinks: _readingPositionEntityGetLinks,
  attach: _readingPositionEntityAttach,
  version: '3.1.0+1',
);

int _readingPositionEntityEstimateSize(
  ReadingPositionEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.verseId.length * 3;
  return bytesCount;
}

void _readingPositionEntitySerialize(
  ReadingPositionEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.lastReadAt);
  writer.writeString(offsets[1], object.verseId);
}

ReadingPositionEntity _readingPositionEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReadingPositionEntity();
  object.id = id;
  object.lastReadAt = reader.readDateTime(offsets[0]);
  object.verseId = reader.readString(offsets[1]);
  return object;
}

P _readingPositionEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _readingPositionEntityGetId(ReadingPositionEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _readingPositionEntityGetLinks(
    ReadingPositionEntity object) {
  return [];
}

void _readingPositionEntityAttach(
    IsarCollection<dynamic> col, Id id, ReadingPositionEntity object) {
  object.id = id;
}

extension ReadingPositionEntityQueryWhereSort
    on QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QWhere> {
  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ReadingPositionEntityQueryWhere on QueryBuilder<ReadingPositionEntity,
    ReadingPositionEntity, QWhereClause> {
  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterWhereClause>
      idBetween(
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

extension ReadingPositionEntityQueryFilter on QueryBuilder<
    ReadingPositionEntity, ReadingPositionEntity, QFilterCondition> {
  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
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

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
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

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
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

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> lastReadAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastReadAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> lastReadAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastReadAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> lastReadAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastReadAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> lastReadAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastReadAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> verseIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> verseIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'verseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> verseIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'verseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> verseIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'verseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> verseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'verseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> verseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'verseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
          QAfterFilterCondition>
      verseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'verseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
          QAfterFilterCondition>
      verseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'verseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> verseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verseId',
        value: '',
      ));
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity,
      QAfterFilterCondition> verseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'verseId',
        value: '',
      ));
    });
  }
}

extension ReadingPositionEntityQueryObject on QueryBuilder<
    ReadingPositionEntity, ReadingPositionEntity, QFilterCondition> {}

extension ReadingPositionEntityQueryLinks on QueryBuilder<ReadingPositionEntity,
    ReadingPositionEntity, QFilterCondition> {}

extension ReadingPositionEntityQuerySortBy
    on QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QSortBy> {
  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterSortBy>
      sortByLastReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAt', Sort.asc);
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterSortBy>
      sortByLastReadAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAt', Sort.desc);
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterSortBy>
      sortByVerseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.asc);
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterSortBy>
      sortByVerseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.desc);
    });
  }
}

extension ReadingPositionEntityQuerySortThenBy
    on QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QSortThenBy> {
  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterSortBy>
      thenByLastReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAt', Sort.asc);
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterSortBy>
      thenByLastReadAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAt', Sort.desc);
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterSortBy>
      thenByVerseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.asc);
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QAfterSortBy>
      thenByVerseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.desc);
    });
  }
}

extension ReadingPositionEntityQueryWhereDistinct
    on QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QDistinct> {
  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QDistinct>
      distinctByLastReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastReadAt');
    });
  }

  QueryBuilder<ReadingPositionEntity, ReadingPositionEntity, QDistinct>
      distinctByVerseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verseId', caseSensitive: caseSensitive);
    });
  }
}

extension ReadingPositionEntityQueryProperty on QueryBuilder<
    ReadingPositionEntity, ReadingPositionEntity, QQueryProperty> {
  QueryBuilder<ReadingPositionEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ReadingPositionEntity, DateTime, QQueryOperations>
      lastReadAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastReadAt');
    });
  }

  QueryBuilder<ReadingPositionEntity, String, QQueryOperations>
      verseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verseId');
    });
  }
}
