import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../l10n/l10n.dart';

@immutable
class AyahBookmarkMarker {
  final String verseId;
  final TextRange range;
  final String? semanticsLabel;

  const AyahBookmarkMarker({
    required this.verseId,
    required this.range,
    this.semanticsLabel,
  });
}

class AyahBookmarkMarkerOverlay extends StatefulWidget {
  final Widget child;
  final List<AyahBookmarkMarker> markers;
  final double iconSize;

  const AyahBookmarkMarkerOverlay({
    super.key,
    required this.child,
    required this.markers,
    this.iconSize = 18,
  });

  @override
  State<AyahBookmarkMarkerOverlay> createState() =>
      _AyahBookmarkMarkerOverlayState();
}

class _AyahBookmarkMarkerOverlayState extends State<AyahBookmarkMarkerOverlay> {
  final GlobalKey _childKey = GlobalKey();
  List<_MarkerPosition> _positions = const [];
  bool _measurementScheduled = false;

  @override
  void didUpdateWidget(covariant AyahBookmarkMarkerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameMarkers(oldWidget.markers, widget.markers) ||
        oldWidget.iconSize != widget.iconSize) {
      _positions = const [];
      _scheduleMeasurement();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.markers.isNotEmpty || _positions.isNotEmpty) {
      _scheduleMeasurement();
    }
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        KeyedSubtree(key: _childKey, child: widget.child),
        for (final position in _positions)
          Positioned(
            key: ValueKey('ayahBookmarkMarker-${position.marker.verseId}'),
            left: position.left,
            top: position.top,
            child: Semantics(
              label: position.marker.semanticsLabel ?? context.l10n.bookmarked,
              container: true,
              child: ExcludeSemantics(
                child: Icon(
                  Icons.bookmark_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: widget.iconSize,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _scheduleMeasurement() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (mounted) _measureMarkers();
    });
  }

  void _measureMarkers() {
    final childRenderObject = _childKey.currentContext?.findRenderObject();
    final paragraph = _findParagraph(childRenderObject);
    if (paragraph == null) return;

    final nextPositions = <_MarkerPosition>[];
    for (final marker in widget.markers) {
      final boxes = paragraph
          .getBoxesForSelection(
            TextSelection(
              baseOffset: marker.range.start,
              extentOffset: marker.range.end,
            ),
          )
          .map((box) => box.toRect())
          .where((rect) => rect.width > 0 && rect.height > 0)
          .toList();
      if (boxes.isEmpty) continue;

      final box = boxes.last;
      final gap = 2.0;
      final left = box.left >= widget.iconSize + gap
          ? box.left - widget.iconSize - gap
          : box.right + gap;
      final clampedLeft = left.clamp(
        0.0,
        (paragraph.size.width - widget.iconSize).clamp(0.0, double.infinity),
      );
      nextPositions.add(
        _MarkerPosition(
          marker: marker,
          left: clampedLeft.toDouble(),
          top: box.center.dy - widget.iconSize / 2,
        ),
      );
    }

    if (!_samePositions(_positions, nextPositions)) {
      setState(() => _positions = nextPositions);
    }
  }

  RenderParagraph? _findParagraph(RenderObject? object) {
    if (object is RenderParagraph) return object;
    RenderParagraph? paragraph;
    object?.visitChildren((child) {
      paragraph ??= _findParagraph(child);
    });
    return paragraph;
  }

  bool _sameMarkers(
    List<AyahBookmarkMarker> first,
    List<AyahBookmarkMarker> second,
  ) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index += 1) {
      if (first[index].verseId != second[index].verseId ||
          first[index].range != second[index].range ||
          first[index].semanticsLabel != second[index].semanticsLabel) {
        return false;
      }
    }
    return true;
  }

  bool _samePositions(
    List<_MarkerPosition> first,
    List<_MarkerPosition> second,
  ) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index += 1) {
      final firstPosition = first[index];
      final secondPosition = second[index];
      if (firstPosition.marker.verseId != secondPosition.marker.verseId ||
          firstPosition.left != secondPosition.left ||
          firstPosition.top != secondPosition.top) {
        return false;
      }
    }
    return true;
  }
}

class _MarkerPosition {
  final AyahBookmarkMarker marker;
  final double left;
  final double top;

  const _MarkerPosition({
    required this.marker,
    required this.left,
    required this.top,
  });
}
