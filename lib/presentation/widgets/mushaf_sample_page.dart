import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class MushafSampleAssets {
  static const Set<int> pages = {1, 2, 3, 604};

  static bool containsPage(int page) => pages.contains(page);

  static String pathForPage(int page) {
    final pageName = page.toString().padLeft(3, '0');
    return 'assets/mushaf/madani-svg-sample/$pageName.svg';
  }
}

class MushafSamplePage extends StatelessWidget {
  static const double aspectRatio = 382.68 / 547.09;

  final int page;

  const MushafSamplePage({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    if (!MushafSampleAssets.containsPage(page)) {
      return _UnsupportedMushafSamplePage(page: page);
    }

    return ColoredBox(
      color: AppTheme.cream,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.divider),
              ),
              child: SvgPicture.asset(
                MushafSampleAssets.pathForPage(page),
                fit: BoxFit.contain,
                semanticsLabel: 'Mushaf page $page sample',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnsupportedMushafSamplePage extends StatelessWidget {
  final int page;

  const _UnsupportedMushafSamplePage({required this.page});

  @override
  Widget build(BuildContext context) {
    final pages = MushafSampleAssets.pages.map((page) => '$page').join(', ');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Mushaf sample is available for pages $pages.\nCurrent page: $page',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
