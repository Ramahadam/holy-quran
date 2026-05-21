// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_position.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReadingPositionCollection on Isar {
  IsarCollection<ReadingPosition> get readingPositions => this.collection();
}

const ReadingPositionSchema = CollectionSchema(
  name: r'ReadingPosition',
  id: -5555304648089438970,
  properties: {
    r'hashCode': PropertySchema(
      id: 0,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'lastReadAt': PropertySchema(
      id: 1,
      name: r'lastReadAt',
      type: IsarType.dateTime,
    ),
    r'verseId': PropertySchema(
      id: 2,
      name: r'verseId',
      type: IsarType.string,
    )
  },
  estimateSize: _readingPositionEstimateSize,
  serialize: _readingPositionSerialize,
  deserialize: _readingPositionDeserialize,
  deserializeProp: _readingPositionDeserializeProp,
  idName: r'id',
  indexes: {
    r'verseId': IndexSchema(
      id: 1744958713610519296,
      name: r'verseId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'verseId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _readingPositionGetId,
  getLinks: _readingPositionGetLinks,
  attach: _readingPositionAttach,
  version: '3.1.0+1',
);

int _readingPositionEstimateSize(
  ReadingPosition object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.verseId.length * 3;
  return bytesCount;
}

void _readingPositionSerialize(
  ReadingPosition object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.hashCode);
  writer.writeDateTime(offsets[1], object.lastReadAt);
  writer.writeString(offsets[2], object.verseId);
}

ReadingPosition _readingPositionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReadingPosition(
    id: id,
    lastReadAt: reader.readDateTime(offsets[1]),
    verseId: reader.readString(offsets[2]),
  );
  return object;
}

P _readingPositionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _readingPositionGetId(ReadingPosition object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _readingPositionGetLinks(ReadingPosition object) {
  return [];
}

void _readingPositionAttach(
    IsarCollection<dynamic> col, Id id, ReadingPosition object) {
  object.id = id;
}

extension ReadingPositionByIndex on IsarCollection<ReadingPosition> {
  Future<ReadingPosition?> getByVerseId(String verseId) {
    return getByIndex(r'verseId', [verseId]);
  }

  ReadingPosition? getByVerseIdSync(String verseId) {
    return getByIndexSync(r'verseId', [verseId]);
  }

  Future<bool> deleteByVerseId(String verseId) {
    return deleteByIndex(r'verseId', [verseId]);
  }

  bool deleteByVerseIdSync(String verseId) {
    return deleteByIndexSync(r'verseId', [verseId]);
  }

  Future<List<ReadingPosition?>> getAllByVerseId(List<String> verseIdValues) {
    final values = verseIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'verseId', values);
  }

  List<ReadingPosition?> getAllByVerseIdSync(List<String> verseIdValues) {
    final values = verseIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'verseId', values);
  }

  Future<int> deleteAllByVerseId(List<String> verseIdValues) {
    final values = verseIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'verseId', values);
  }

  int deleteAllByVerseIdSync(List<String> verseIdValues) {
    final values = verseIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'verseId', values);
  }

  Future<Id> putByVerseId(ReadingPosition object) {
    return putByIndex(r'verseId', object);
  }

  Id putByVerseIdSync(ReadingPosition object, {bool saveLinks = true}) {
    return putByIndexSync(r'verseId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByVerseId(List<ReadingPosition> objects) {
    return putAllByIndex(r'verseId', objects);
  }

  List<Id> putAllByVerseIdSync(List<ReadingPosition> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'verseId', objects, saveLinks: saveLinks);
  }
}

extension ReadingPositionQueryWhereSort
    on QueryBuilder<ReadingPosition, ReadingPosition, QWhere> {
  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ReadingPositionQueryWhere
    on QueryBuilder<ReadingPosition, ReadingPosition, QWhereClause> {
  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause> idBetween(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
      verseIdEqualTo(String verseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'verseId',
        value: [verseId],
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterWhereClause>
      verseIdNotEqualTo(String verseId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'verseId',
              lower: [],
              upper: [verseId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'verseId',
              lower: [verseId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'verseId',
              lower: [verseId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'verseId',
              lower: [],
              upper: [verseId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ReadingPositionQueryFilter
    on QueryBuilder<ReadingPosition, ReadingPosition, QFilterCondition> {
  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      hashCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      hashCodeGreaterThan(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      hashCodeLessThan(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      hashCodeBetween(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      lastReadAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastReadAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      lastReadAtGreaterThan(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      lastReadAtLessThan(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      lastReadAtBetween(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      verseIdEqualTo(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      verseIdGreaterThan(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      verseIdLessThan(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      verseIdBetween(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      verseIdStartsWith(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      verseIdEndsWith(
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

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      verseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'verseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      verseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'verseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      verseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verseId',
        value: '',
      ));
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterFilterCondition>
      verseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'verseId',
        value: '',
      ));
    });
  }
}

extension ReadingPositionQueryObject
    on QueryBuilder<ReadingPosition, ReadingPosition, QFilterCondition> {}

extension ReadingPositionQueryLinks
    on QueryBuilder<ReadingPosition, ReadingPosition, QFilterCondition> {}

extension ReadingPositionQuerySortBy
    on QueryBuilder<ReadingPosition, ReadingPosition, QSortBy> {
  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      sortByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      sortByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      sortByLastReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAt', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      sortByLastReadAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAt', Sort.desc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy> sortByVerseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      sortByVerseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.desc);
    });
  }
}

extension ReadingPositionQuerySortThenBy
    on QueryBuilder<ReadingPosition, ReadingPosition, QSortThenBy> {
  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      thenByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      thenByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      thenByLastReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAt', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      thenByLastReadAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastReadAt', Sort.desc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy> thenByVerseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.asc);
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QAfterSortBy>
      thenByVerseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.desc);
    });
  }
}

extension ReadingPositionQueryWhereDistinct
    on QueryBuilder<ReadingPosition, ReadingPosition, QDistinct> {
  QueryBuilder<ReadingPosition, ReadingPosition, QDistinct>
      distinctByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hashCode');
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QDistinct>
      distinctByLastReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastReadAt');
    });
  }

  QueryBuilder<ReadingPosition, ReadingPosition, QDistinct> distinctByVerseId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verseId', caseSensitive: caseSensitive);
    });
  }
}

extension ReadingPositionQueryProperty
    on QueryBuilder<ReadingPosition, ReadingPosition, QQueryProperty> {
  QueryBuilder<ReadingPosition, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ReadingPosition, int, QQueryOperations> hashCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashCode');
    });
  }

  QueryBuilder<ReadingPosition, DateTime, QQueryOperations>
      lastReadAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastReadAt');
    });
  }

  QueryBuilder<ReadingPosition, String, QQueryOperations> verseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verseId');
    });
  }
}
