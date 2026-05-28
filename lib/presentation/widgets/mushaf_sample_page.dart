import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import 'mushaf_hit_testing.dart';

class MushafSampleAssets {
  static const Set<int> pages = {1, 2, 3, 604};
  static const String coordinatesPath =
      'assets/mushaf/madani-svg-sample/coordinates.sample.json';

  static bool containsPage(int page) => pages.contains(page);

  static String pathForPage(int page) {
    final pageName = page.toString().padLeft(3, '0');
    return 'assets/mushaf/madani-svg-sample/$pageName.svg';
  }
}

class MushafSamplePage extends StatefulWidget {
  static const double aspectRatio = 382.68 / 547.09;

  final int page;
  final ValueChanged<MushafHitResult>? onHit;

  const MushafSamplePage({super.key, required this.page, this.onHit});

  @override
  State<MushafSamplePage> createState() => _MushafSamplePageState();
}

class _MushafSamplePageState extends State<MushafSamplePage> {
  final GlobalKey _pageKey = GlobalKey();
  Future<MushafCoordinateRepository>? _coordinateRepository;

  Future<MushafCoordinateRepository> _loadCoordinateRepository() {
    return _coordinateRepository ??= MushafCoordinateRepository.loadFromAsset(
      DefaultAssetBundle.of(context),
      MushafSampleAssets.coordinatesPath,
    );
  }

  Future<void> _handleTapUp(TapUpDetails details) async {
    if (widget.onHit == null) return;

    final renderObject = _pageKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final normalizedPoint = MushafPageGeometry.normalizedPoint(
      localPosition: renderObject.globalToLocal(details.globalPosition),
      size: renderObject.size,
    );
    if (normalizedPoint == null) return;

    final repository = await _loadCoordinateRepository();
    if (!mounted) return;

    final hit = repository.hitTest(
      page: widget.page,
      normalizedPoint: normalizedPoint,
    );
    if (hit != null) widget.onHit?.call(hit);
  }

  @override
  Widget build(BuildContext context) {
    if (!MushafSampleAssets.containsPage(widget.page)) {
      return _UnsupportedMushafSamplePage(page: widget.page);
    }

    return ColoredBox(
      color: AppTheme.cream,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: AspectRatio(
            aspectRatio: MushafSamplePage.aspectRatio,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _handleTapUp,
              child: DecoratedBox(
                key: _pageKey,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.divider),
                ),
                child: SvgPicture.asset(
                  MushafSampleAssets.pathForPage(widget.page),
                  fit: BoxFit.contain,
                  semanticsLabel: 'Mushaf page ${widget.page} sample',
                ),
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
