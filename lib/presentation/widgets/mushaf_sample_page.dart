import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import 'mushaf_hit_testing.dart';

class MushafSampleAssets {
  static const int firstPage = 1;
  static const int lastPage = 604;
  static const Set<int> svgSamplePages = {1, 2, 3, 604};
  static const String coordinatesPath =
      'assets/mushaf/madani-svg-sample/coordinates.sample.json';

  static bool containsPage(int page) => page >= firstPage && page <= lastPage;

  static bool hasSvgSampleForPage(int page) => svgSamplePages.contains(page);

  static String imagePathForPage(int page) {
    final pageName = page.toString().padLeft(3, '0');
    return 'assets/mushaf/madani-images/$pageName.png';
  }

  static String svgPathForPage(int page) {
    final pageName = page.toString().padLeft(3, '0');
    return 'assets/mushaf/madani-svg-sample/$pageName.svg';
  }

  static String pathForPage(int page) => svgPathForPage(page);
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
                child: _MushafPageImage(page: widget.page),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Mushaf pages run from 1 to 604.\nCurrent page: $page',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _MushafPageImage extends StatelessWidget {
  final int page;

  const _MushafPageImage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      MushafSampleAssets.imagePathForPage(page),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (MushafSampleAssets.hasSvgSampleForPage(page)) {
          return _MushafSvgPage(
            page: page,
            semanticsLabel: 'Mushaf page $page',
          );
        }

        return _MissingMushafImagePage(page: page);
      },
    );
  }
}

class _MushafSvgPage extends StatelessWidget {
  final int page;
  final String semanticsLabel;

  const _MushafSvgPage({required this.page, required this.semanticsLabel});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      MushafSampleAssets.svgPathForPage(page),
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel,
    );
  }
}

class _MissingMushafImagePage extends StatelessWidget {
  final int page;

  const _MissingMushafImagePage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Mushaf image missing for page ${page.toString().padLeft(3, '0')}',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
