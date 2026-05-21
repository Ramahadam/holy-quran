// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVerseEntityCollection on Isar {
  IsarCollection<VerseEntity> get verseEntitys => this.collection();
}

const VerseEntitySchema = CollectionSchema(
  name: r'VerseEntity',
  id: -5496938192407533235,
  properties: {
    r'arabicText': PropertySchema(
      id: 0,
      name: r'arabicText',
      type: IsarType.string,
    ),
    r'surahNumber': PropertySchema(
      id: 1,
      name: r'surahNumber',
      type: IsarType.long,
    ),
    r'translation': PropertySchema(
      id: 2,
      name: r'translation',
      type: IsarType.string,
    ),
    r'verseId': PropertySchema(
      id: 3,
      name: r'verseId',
      type: IsarType.string,
    ),
    r'verseNumber': PropertySchema(
      id: 4,
      name: r'verseNumber',
      type: IsarType.long,
    )
  },
  estimateSize: _verseEntityEstimateSize,
  serialize: _verseEntitySerialize,
  deserialize: _verseEntityDeserialize,
  deserializeProp: _verseEntityDeserializeProp,
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
    ),
    r'surahNumber': IndexSchema(
      id: 9024003441292455669,
      name: r'surahNumber',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'surahNumber',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _verseEntityGetId,
  getLinks: _verseEntityGetLinks,
  attach: _verseEntityAttach,
  version: '3.1.0+1',
);

int _verseEntityEstimateSize(
  VerseEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.arabicText.length * 3;
  {
    final value = object.translation;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.verseId.length * 3;
  return bytesCount;
}

void _verseEntitySerialize(
  VerseEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.arabicText);
  writer.writeLong(offsets[1], object.surahNumber);
  writer.writeString(offsets[2], object.translation);
  writer.writeString(offsets[3], object.verseId);
  writer.writeLong(offsets[4], object.verseNumber);
}

VerseEntity _verseEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = VerseEntity();
  object.arabicText = reader.readString(offsets[0]);
  object.id = id;
  object.surahNumber = reader.readLong(offsets[1]);
  object.translation = reader.readStringOrNull(offsets[2]);
  object.verseId = reader.readString(offsets[3]);
  object.verseNumber = reader.readLong(offsets[4]);
  return object;
}

P _verseEntityDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _verseEntityGetId(VerseEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _verseEntityGetLinks(VerseEntity object) {
  return [];
}

void _verseEntityAttach(
    IsarCollection<dynamic> col, Id id, VerseEntity object) {
  object.id = id;
}

extension VerseEntityByIndex on IsarCollection<VerseEntity> {
  Future<VerseEntity?> getByVerseId(String verseId) {
    return getByIndex(r'verseId', [verseId]);
  }

  VerseEntity? getByVerseIdSync(String verseId) {
    return getByIndexSync(r'verseId', [verseId]);
  }

  Future<bool> deleteByVerseId(String verseId) {
    return deleteByIndex(r'verseId', [verseId]);
  }

  bool deleteByVerseIdSync(String verseId) {
    return deleteByIndexSync(r'verseId', [verseId]);
  }

  Future<List<VerseEntity?>> getAllByVerseId(List<String> verseIdValues) {
    final values = verseIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'verseId', values);
  }

  List<VerseEntity?> getAllByVerseIdSync(List<String> verseIdValues) {
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

  Future<Id> putByVerseId(VerseEntity object) {
    return putByIndex(r'verseId', object);
  }

  Id putByVerseIdSync(VerseEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'verseId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByVerseId(List<VerseEntity> objects) {
    return putAllByIndex(r'verseId', objects);
  }

  List<Id> putAllByVerseIdSync(List<VerseEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'verseId', objects, saveLinks: saveLinks);
  }
}

extension VerseEntityQueryWhereSort
    on QueryBuilder<VerseEntity, VerseEntity, QWhere> {
  QueryBuilder<VerseEntity, VerseEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhere> anySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'surahNumber'),
      );
    });
  }
}

extension VerseEntityQueryWhere
    on QueryBuilder<VerseEntity, VerseEntity, QWhereClause> {
  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause> idBetween(
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause> verseIdEqualTo(
      String verseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'verseId',
        value: [verseId],
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause> verseIdNotEqualTo(
      String verseId) {
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause> surahNumberEqualTo(
      int surahNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'surahNumber',
        value: [surahNumber],
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause>
      surahNumberNotEqualTo(int surahNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber',
              lower: [],
              upper: [surahNumber],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber',
              lower: [surahNumber],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber',
              lower: [surahNumber],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'surahNumber',
              lower: [],
              upper: [surahNumber],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause>
      surahNumberGreaterThan(
    int surahNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahNumber',
        lower: [surahNumber],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause> surahNumberLessThan(
    int surahNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahNumber',
        lower: [],
        upper: [surahNumber],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterWhereClause> surahNumberBetween(
    int lowerSurahNumber,
    int upperSurahNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'surahNumber',
        lower: [lowerSurahNumber],
        includeLower: includeLower,
        upper: [upperSurahNumber],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VerseEntityQueryFilter
    on QueryBuilder<VerseEntity, VerseEntity, QFilterCondition> {
  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      arabicTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'arabicText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      arabicTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'arabicText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      arabicTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'arabicText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      arabicTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'arabicText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      arabicTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'arabicText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      arabicTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'arabicText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      arabicTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'arabicText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      arabicTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'arabicText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      arabicTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'arabicText',
        value: '',
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      arabicTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'arabicText',
        value: '',
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition> idBetween(
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      surahNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'surahNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'translation',
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'translation',
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'translation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'translation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'translation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'translation',
        value: '',
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      translationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'translation',
        value: '',
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition> verseIdEqualTo(
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition> verseIdLessThan(
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition> verseIdBetween(
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition> verseIdEndsWith(
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

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition> verseIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'verseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition> verseIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'verseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      verseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verseId',
        value: '',
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      verseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'verseId',
        value: '',
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      verseNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verseNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      verseNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'verseNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      verseNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'verseNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterFilterCondition>
      verseNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'verseNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VerseEntityQueryObject
    on QueryBuilder<VerseEntity, VerseEntity, QFilterCondition> {}

extension VerseEntityQueryLinks
    on QueryBuilder<VerseEntity, VerseEntity, QFilterCondition> {}

extension VerseEntityQuerySortBy
    on QueryBuilder<VerseEntity, VerseEntity, QSortBy> {
  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> sortByArabicText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arabicText', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> sortByArabicTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arabicText', Sort.desc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> sortBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> sortBySurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.desc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> sortByTranslation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translation', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> sortByTranslationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translation', Sort.desc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> sortByVerseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> sortByVerseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.desc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> sortByVerseNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseNumber', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> sortByVerseNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseNumber', Sort.desc);
    });
  }
}

extension VerseEntityQuerySortThenBy
    on QueryBuilder<VerseEntity, VerseEntity, QSortThenBy> {
  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenByArabicText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arabicText', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenByArabicTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arabicText', Sort.desc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenBySurahNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surahNumber', Sort.desc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenByTranslation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translation', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenByTranslationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translation', Sort.desc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenByVerseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenByVerseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseId', Sort.desc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenByVerseNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseNumber', Sort.asc);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QAfterSortBy> thenByVerseNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verseNumber', Sort.desc);
    });
  }
}

extension VerseEntityQueryWhereDistinct
    on QueryBuilder<VerseEntity, VerseEntity, QDistinct> {
  QueryBuilder<VerseEntity, VerseEntity, QDistinct> distinctByArabicText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'arabicText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QDistinct> distinctBySurahNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surahNumber');
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QDistinct> distinctByTranslation(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'translation', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QDistinct> distinctByVerseId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VerseEntity, VerseEntity, QDistinct> distinctByVerseNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verseNumber');
    });
  }
}

extension VerseEntityQueryProperty
    on QueryBuilder<VerseEntity, VerseEntity, QQueryProperty> {
  QueryBuilder<VerseEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<VerseEntity, String, QQueryOperations> arabicTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'arabicText');
    });
  }

  QueryBuilder<VerseEntity, int, QQueryOperations> surahNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surahNumber');
    });
  }

  QueryBuilder<VerseEntity, String?, QQueryOperations> translationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translation');
    });
  }

  QueryBuilder<VerseEntity, String, QQueryOperations> verseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verseId');
    });
  }

  QueryBuilder<VerseEntity, int, QQueryOperations> verseNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verseNumber');
    });
  }
}
