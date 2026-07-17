import 'dart:ui' show BoxHeightStyle;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:holy_quran_app/presentation/widgets/mushaf_sample_page.dart';

void main() {
  testWidgets('all 604 Mushaf pages keep their printed lines and final glyph', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    for (var page = 1; page <= 604; page += 1) {
      final pageName = page.toString().padLeft(3, '0');
      await (FontLoader('packages/qcf_quran/QCF_P$pageName')..addFont(
            rootBundle.load(
              'packages/qcf_quran/assets/fonts/qcf4/'
              'QCF4${pageName}_X-Regular.woff',
            ),
          ))
          .load();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: MushafSamplePage(key: ValueKey(page), page: page),
            ),
          ),
        ),
      );
      await tester.pump();

      final textFinder = find.byKey(ValueKey('mushafPageText-$page'));
      final paragraph = tester.renderObject<RenderParagraph>(textFinder);
      final textLength = paragraph.text
          .toPlainText(includeSemanticsLabels: false)
          .trimRight()
          .length;
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: textLength),
        boxHeightStyle: BoxHeightStyle.max,
      );
      final lineTops = <double>[];
      for (final box in boxes) {
        if (lineTops.every((top) => (top - box.top).abs() > .5)) {
          lineTops.add(box.top);
        }
      }

      if (page >= 3) {
        expect(lineTops, hasLength(15), reason: 'Page $page line count.');
      }
      final surface = tester.getRect(
        find.byKey(const ValueKey('canonicalMushafPageSurface')),
      );
      final lastBox = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: textLength - 1, extentOffset: textLength),
      );
      expect(lastBox, isNotEmpty, reason: 'Page $page final glyph.');
      expect(
        paragraph.localToGlobal(Offset(0, lastBox.last.bottom)).dy,
        lessThanOrEqualTo(surface.bottom + .5),
        reason: 'Page $page final glyph clipped.',
      );
      expect(tester.takeException(), isNull, reason: 'Page $page overflowed.');
    }
  });
}
