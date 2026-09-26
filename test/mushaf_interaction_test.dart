import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran/qcf_quran.dart';

import 'package:holy_quran_app/presentation/theme/app_theme.dart';
import 'package:holy_quran_app/presentation/widgets/mushaf_sample_page.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('packages/qcf_quran/QCF_P003')..addFont(
          rootBundle.load(
            'packages/qcf_quran/assets/fonts/qcf4/'
            'QCF4003_X-Regular.woff',
          ),
        ))
        .load();
    await (FontLoader('packages/qcf_quran/QCF_P604')..addFont(
          rootBundle.load(
            'packages/qcf_quran/assets/fonts/qcf4/'
            'QCF4604_X-Regular.woff',
          ),
        ))
        .load();
    await (FontLoader('packages/qcf_quran/QCF_P019')..addFont(
          rootBundle.load(
            'packages/qcf_quran/assets/fonts/qcf4/'
            'QCF4019_X-Regular.woff',
          ),
        ))
        .load();
  });

  testWidgets('single tap on the page invokes only the page action', (
    tester,
  ) async {
    var pageTapCount = 0;
    String? longPressedVerseId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MushafSamplePage(
            page: 3,
            onPageTap: () => pageTapCount += 1,
            onVerseLongPress: (verseId) => longPressedVerseId = verseId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final surface = tester.getRect(
      find.byKey(const ValueKey('canonicalMushafPageSurface')),
    );
    await tester.tapAt(surface.center);
    await tester.pump();

    expect(pageTapCount, 1);
    expect(longPressedVerseId, isNull);
    final qcfPage = tester.widget<MushafQcfPage>(find.byType(MushafQcfPage));
    expect(qcfPage.onTap, isNull);
    expect(qcfPage.onLongPress, isNotNull);
  });

  testWidgets('long press anywhere in an ayah resolves its stable VerseID', (
    tester,
  ) async {
    String? longPressedVerseId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MushafSamplePage(
            page: 3,
            onVerseLongPress: (verseId) => longPressedVerseId = verseId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(const ValueKey('mushafPageText-3')),
    );
    final firstGlyphBox = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .single;
    await tester.longPressAt(
      paragraph.localToGlobal(firstGlyphBox.toRect().center),
    );
    await tester.pump();

    expect(longPressedVerseId, '2:6');
  });

  testWidgets('exposes one stable, readable semantic identity per ayah', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var accessiblePageTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MushafSamplePage(
            page: 3,
            bookmarkedVerseIds: const {'2:6'},
            onPageTap: () => accessiblePageTapCount += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pageControls = _semanticsByIdentifier('mushaf-page-controls');
    expect(pageControls, findsOne);
    final pageControlsData = pageControls.evaluate().single.getSemanticsData();
    expect(pageControlsData.label, contains('أدوات القراءة'));
    expect(pageControlsData.hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(pageControls);
    expect(accessiblePageTapCount, 1);

    for (var verse = 6; verse <= 16; verse += 1) {
      final verseSemantics = _semanticsByIdentifier('mushaf-verse-2-$verse');
      expect(
        verseSemantics,
        findsOne,
        reason: 'Page 3 is missing semantics for verse 2:$verse.',
      );
    }
    final bookmarkedVerse = _semanticsByIdentifier(
      'mushaf-verse-2-6',
    ).evaluate().single.getSemanticsData();
    expect(bookmarkedVerse.label, contains('الآية ٦'));
    expect(bookmarkedVerse.label, contains('محفوظة'));
    semantics.dispose();
  });

  testWidgets('bookmark indication is overlaid beside the ayah marker', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MushafSamplePage(page: 3, bookmarkedVerseIds: {'2:6'}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(
      find.byKey(const ValueKey('mushafPageText-3')),
    );
    final verseNumberSpan = _textSpans(
      text.textSpan!,
    ).singleWhere((span) => span.text == getVerseNumberQCF(2, 6));

    expect(verseNumberSpan.style?.backgroundColor, isNull);
    expect(
      find.byKey(const ValueKey('ayahBookmarkMarker-2:6')),
      findsOneWidget,
    );
  });

  testWidgets('bookmark stays above its ornament across page layouts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final (page, surah, verse) in const [
      (3, 2, 6),
      (19, 2, 120),
      (604, 112, 1),
    ]) {
      final verseId = '$surah:$verse';
      for (final size in const [Size(360, 800), Size(800, 600)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MushafSamplePage(
                key: ValueKey('$page-$size'),
                page: page,
                bookmarkedVerseIds: {verseId},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final ornament = _ornamentRect(tester, page, surah, verse);
        final bookmark = tester.getRect(
          find.byKey(ValueKey('ayahBookmarkMarker-$verseId')),
        );
        final pageSurface = tester.getRect(
          find.byKey(const ValueKey('canonicalMushafPageSurface')),
        );
        expect(
          (bookmark.center.dx - ornament.center.dx).abs(),
          lessThan(8),
          reason: '$verseId $size',
        );
        expect(bookmark.bottom, lessThan(ornament.center.dy));
        expect(pageSurface.contains(bookmark.topLeft), isTrue);
        expect(pageSurface.contains(bookmark.bottomRight), isTrue);
      }
    }
  });

  testWidgets('bookmark indication resolves after an inline Surah header', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MushafSamplePage(page: 604, bookmarkedVerseIds: {'112:1'}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('ayahBookmarkMarker-112:1')),
      findsOneWidget,
    );
    final text = tester.widget<Text>(
      find.byKey(const ValueKey('mushafPageText-604')),
    );
    final verseNumberSpan = _textSpans(
      text.textSpan!,
    ).singleWhere((span) => span.text == getVerseNumberQCF(112, 1));
    expect(verseNumberSpan.style?.backgroundColor, isNull);
  });

  testWidgets('adjacent bookmarked ayahs keep separate markers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MushafSamplePage(
            page: 604,
            bookmarkedVerseIds: {'112:1', '112:2', '112:3', '112:4'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final markerRects = <Rect>[];
    for (final verse in const [1, 2, 3, 4]) {
      final marker = tester.getRect(
        find.byKey(ValueKey('ayahBookmarkMarker-112:$verse')),
      );
      expect(
        markerRects.every((other) => !other.overlaps(marker)),
        isTrue,
        reason: 'Bookmark for 112:$verse overlaps an adjacent bookmark.',
      );
      markerRects.add(marker);
    }
  });

  testWidgets('keeps Allah glyphs highlighted with public Quran text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MushafSamplePage(page: 1))),
    );
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(
      find.byKey(const ValueKey('mushafPageText-1')),
    );
    final highlightedGlyphs = _textSpans(
      text.textSpan!,
    ).where((span) => span.style?.color == AppTheme.quranRed);

    expect(highlightedGlyphs, isNotEmpty);
  });
}

SemanticsFinder _semanticsByIdentifier(String identifier) =>
    find.semantics.byPredicate((node) => node.identifier == identifier);

Iterable<TextSpan> _textSpans(InlineSpan span) sync* {
  if (span is TextSpan) {
    yield span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      yield* _textSpans(child);
    }
  }
}

Rect _ornamentRect(WidgetTester tester, int page, int surah, int verse) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.byKey(ValueKey('mushafPageText-$page')),
  );
  final text = tester.widget<Text>(
    find.byKey(ValueKey('mushafPageText-$page')),
  );
  final glyph = getVerseNumberQCF(surah, verse);
  final offset = text.textSpan!
      .toPlainText(includeSemanticsLabels: false, includePlaceholders: true)
      .indexOf(glyph);
  expect(offset, greaterThanOrEqualTo(0));
  final rect = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + glyph.length),
      )
      .single
      .toRect();
  return Rect.fromPoints(
    paragraph.localToGlobal(rect.topLeft),
    paragraph.localToGlobal(rect.bottomRight),
  );
}
