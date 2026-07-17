import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:holy_quran_app/presentation/widgets/mushaf_sample_page.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      mushafSurahTitleFontFamily,
    )..addFont(rootBundle.load('assets/fonts/UthmanicHafs_V22.ttf'))).load();

    for (final page in const [1, 2, 3, 446, 452, 456, 604]) {
      final pageName = page.toString().padLeft(3, '0');
      await (FontLoader('packages/qcf_quran/QCF_P$pageName')..addFont(
            rootBundle.load(
              'packages/qcf_quran/assets/fonts/qcf4/'
              'QCF4${pageName}_X-Regular.woff',
            ),
          ))
          .load();
    }
  });

  for (final page in const [1, 2, 3, 446, 452, 456, 604]) {
    testWidgets('canonical Mushaf page $page', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: RepaintBoundary(
              key: ValueKey('mushaf-golden-$page'),
              child: MushafSamplePage(page: page),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chromeFinder = find.byKey(
        const ValueKey('mushafSingleSlotChromeBackground'),
      );
      if (chromeFinder.evaluate().isNotEmpty) {
        final chrome = tester.widget<Image>(chromeFinder.first);
        await tester.runAsync(
          () => precacheImage(chrome.image, tester.element(chromeFinder.first)),
        );
        await tester.pumpAndSettle();
      }

      await expectLater(
        find.byKey(ValueKey('mushaf-golden-$page')),
        matchesGoldenFile('goldens/mushaf_page_$page.png'),
      );
    });
  }
}
