import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_quran_app/presentation/widgets/mushaf_hit_testing.dart';
import 'package:holy_quran_app/presentation/widgets/mushaf_sample_page.dart';

const _firstWordCenter = Offset(
  0.562689 + 0.079178 / 2,
  0.517995 + 0.023506 / 2,
);
const _firstAyahMarkerCenter = Offset(
  0.371773 + 0.032403 / 2,
  0.511488 + 0.028076 / 2,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MushafPageGeometry', () {
    test('translates local page coordinates into normalized coordinates', () {
      expect(
        MushafPageGeometry.normalizedPoint(
          localPosition: const Offset(50, 100),
          size: const Size(100, 200),
        ),
        const Offset(0.5, 0.5),
      );
    });

    test('ignores taps outside the page bounds', () {
      expect(
        MushafPageGeometry.normalizedPoint(
          localPosition: const Offset(-1, 100),
          size: const Size(100, 200),
        ),
        isNull,
      );
    });
  });

  group('MushafCoordinateRepository', () {
    late MushafCoordinateRepository repository;

    setUp(() {
      final source = File(
        MushafSampleAssets.coordinatesPath,
      ).readAsStringSync();
      repository = MushafCoordinateRepository.fromJsonString(source);
    });

    test('maps a normalized word hit to verse and word index', () {
      final hit = repository.hitTest(
        page: 1,
        normalizedPoint: _firstWordCenter,
      );

      expect(hit, isNotNull);
      expect(hit!.verseId, '1:1');
      expect(hit.wordIndex, 1);
      expect(hit.region.type, MushafHitRegionType.word);
    });

    test('maps an ayah marker hit to verse without a word index', () {
      final hit = repository.hitTest(
        page: 1,
        normalizedPoint: _firstAyahMarkerCenter,
      );

      expect(hit, isNotNull);
      expect(hit!.verseId, '1:1');
      expect(hit.wordIndex, isNull);
      expect(hit.region.type, MushafHitRegionType.ayahMarker);
    });

    test('derives verse-level hit regions from words and ayah markers', () {
      final page = repository.page(1)!;
      final regions = page.regionsForVerse('1:1');
      final bounds = page.verseBounds('1:1');

      expect(regions, hasLength(5));
      expect(
        regions.map((region) => region.type),
        contains(MushafHitRegionType.ayahMarker),
      );
      expect(bounds, isNotNull);
      expect(bounds!.left, closeTo(0.371773, 0.000001));
      expect(bounds.right, closeTo(0.641867, 0.000001));
    });
  });

  group('MushafSamplePage hit testing', () {
    testWidgets('exposes QCF verse long presses as stable VerseIDs', (
      tester,
    ) async {
      String? pressedVerseId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafSamplePage(
              page: 1,
              onVerseLongPress: (verseId) => pressedVerseId = verseId,
            ),
          ),
        ),
      );
      await tester.pump();

      final qcfPage = tester.widget<MushafQcfPage>(find.byType(MushafQcfPage));
      expect(qcfPage.onTap, isNull);
      qcfPage.onLongPress?.call(1, 1);

      expect(pressedVerseId, '1:1');
    });
  });
}
