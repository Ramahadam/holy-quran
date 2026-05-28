import 'dart:convert';

import 'package:flutter/services.dart';

enum MushafHitRegionType { word, ayahMarker }

class MushafHitRegion {
  final MushafHitRegionType type;
  final String verseId;
  final int line;
  final Rect bounds;
  final String sourceId;
  final int? wordIndex;

  const MushafHitRegion({
    required this.type,
    required this.verseId,
    required this.line,
    required this.bounds,
    required this.sourceId,
    this.wordIndex,
  });

  bool contains(Offset normalizedPoint) => bounds.contains(normalizedPoint);
}

class MushafHitResult {
  final String verseId;
  final int? wordIndex;
  final MushafHitRegion region;
  final List<MushafHitRegion> verseRegions;
  final Rect verseBounds;

  const MushafHitResult({
    required this.verseId,
    required this.wordIndex,
    required this.region,
    required this.verseRegions,
    required this.verseBounds,
  });
}

class MushafCoordinatePage {
  final int page;
  final List<MushafHitRegion> regions;

  MushafCoordinatePage({
    required this.page,
    required Iterable<MushafHitRegion> regions,
  }) : regions = List.unmodifiable(regions);

  MushafHitResult? hitTest(Offset normalizedPoint) {
    final matchingRegions =
        regions.where((region) => region.contains(normalizedPoint)).toList()
          ..sort(_compareHitRegions);
    if (matchingRegions.isEmpty) return null;

    final region = matchingRegions.first;
    final verseRegions = regionsForVerse(region.verseId);
    final bounds = verseBounds(region.verseId);
    if (bounds == null) return null;

    return MushafHitResult(
      verseId: region.verseId,
      wordIndex: region.wordIndex,
      region: region,
      verseRegions: verseRegions,
      verseBounds: bounds,
    );
  }

  List<MushafHitRegion> regionsForVerse(String verseId) {
    return List.unmodifiable(
      regions.where((region) => region.verseId == verseId),
    );
  }

  Rect? verseBounds(String verseId) {
    final verseRegions = regionsForVerse(verseId);
    if (verseRegions.isEmpty) return null;

    var bounds = verseRegions.first.bounds;
    for (final region in verseRegions.skip(1)) {
      bounds = bounds.expandToInclude(region.bounds);
    }
    return bounds;
  }

  static int _compareHitRegions(MushafHitRegion a, MushafHitRegion b) {
    if (a.type != b.type) {
      return a.type == MushafHitRegionType.word ? -1 : 1;
    }
    return _area(a.bounds).compareTo(_area(b.bounds));
  }

  static double _area(Rect rect) => rect.width * rect.height;
}

class MushafCoordinateRepository {
  final Map<int, MushafCoordinatePage> _pages;

  const MushafCoordinateRepository._(this._pages);

  static Future<MushafCoordinateRepository> loadFromAsset(
    AssetBundle bundle,
    String assetPath,
  ) async {
    final source = await bundle.loadString(assetPath);
    return MushafCoordinateRepository.fromJsonString(source);
  }

  factory MushafCoordinateRepository.fromJsonString(String source) {
    final data = jsonDecode(source) as Map<String, Object?>;
    final pages = data['pages'] as List<Object?>;
    final parsedPages = <int, MushafCoordinatePage>{};

    for (final pageData in pages.cast<Map<String, Object?>>()) {
      final pageNumber = (pageData['page'] as num).toInt();
      final items = pageData['items'] as List<Object?>;
      final regions = items
          .cast<Map<String, Object?>>()
          .map(_parseRegion)
          .toList(growable: false);
      parsedPages[pageNumber] = MushafCoordinatePage(
        page: pageNumber,
        regions: regions,
      );
    }

    return MushafCoordinateRepository._(Map.unmodifiable(parsedPages));
  }

  MushafCoordinatePage? page(int pageNumber) => _pages[pageNumber];

  MushafHitResult? hitTest({
    required int page,
    required Offset normalizedPoint,
  }) {
    return _pages[page]?.hitTest(normalizedPoint);
  }

  static MushafHitRegion _parseRegion(Map<String, Object?> data) {
    final type = switch (data['type']) {
      'word' => MushafHitRegionType.word,
      'ayahMarker' => MushafHitRegionType.ayahMarker,
      final value => throw FormatException(
        'Unknown Mushaf region type: $value',
      ),
    };
    final bounds = data['bounds'] as Map<String, Object?>;

    return MushafHitRegion(
      type: type,
      verseId: data['verseId'] as String,
      line: (data['line'] as num).toInt(),
      bounds: Rect.fromLTWH(
        (bounds['x'] as num).toDouble(),
        (bounds['y'] as num).toDouble(),
        (bounds['w'] as num).toDouble(),
        (bounds['h'] as num).toDouble(),
      ),
      sourceId: data['sourceId'] as String,
      wordIndex: (data['wordIndex'] as num?)?.toInt(),
    );
  }
}

class MushafPageGeometry {
  const MushafPageGeometry._();

  static Offset? normalizedPoint({
    required Offset localPosition,
    required Size size,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;

    final normalized = Offset(
      localPosition.dx / size.width,
      localPosition.dy / size.height,
    );
    if (normalized.dx < 0 ||
        normalized.dy < 0 ||
        normalized.dx > 1 ||
        normalized.dy > 1) {
      return null;
    }

    return normalized;
  }
}
