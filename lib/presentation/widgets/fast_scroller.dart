import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A draggable fast-scroll handle with a position bubble for long lists.
///
/// The handle appears on the scrollbar edge (left in RTL) when the user
/// scrolls, fades after a short idle period, and is omitted when the content
/// is less than two screens long. While it is dragged, [labelBuilder] names
/// the current position (for example "2 · البقرة").
class FastScroller extends StatefulWidget {
  final ScrollController controller;
  final Widget child;
  final String? Function()? labelBuilder;

  const FastScroller({
    super.key,
    required this.controller,
    required this.child,
    this.labelBuilder,
  });

  @override
  State<FastScroller> createState() => _FastScrollerState();
}

class _FastScrollerState extends State<FastScroller> {
  static const _handleHeight = 56.0;
  static const _handleWidth = 32.0;
  static const _hideDelay = Duration(milliseconds: 1500);

  bool _visible = false;
  bool _dragging = false;
  // Where the finger is while dragging; lazily built lists re-estimate their
  // extent on every jump, so the handle follows the finger, not the offset.
  double _dragFraction = 0;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final userScrolled =
        notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle;
    if (userScrolled && !_visible) setState(() => _visible = true);
    if (_visible && notification is ScrollUpdateNotification) _scheduleHide();
    if (userScrolled) _scheduleHide();
    return false;
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (mounted && !_dragging) setState(() => _visible = false);
    });
  }

  void _dragTo(Offset globalPosition, double trackHeight) {
    final box = context.findRenderObject() as RenderBox?;
    final position = widget.controller.position;
    if (box == null) return;
    final local = box.globalToLocal(globalPosition);
    final fraction =
        ((local.dy - _handleHeight / 2) / (trackHeight - _handleHeight)).clamp(
          0.0,
          1.0,
        );
    _dragFraction = fraction;
    position.jumpTo(fraction * position.maxScrollExtent);
    // Rows are laid out at the new offset only after this frame; refresh the
    // label once they are.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _dragging) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = constraints.maxHeight;
        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: widget.child,
            ),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) =>
                  _buildHandle(context, trackHeight) ?? const SizedBox(),
            ),
          ],
        );
      },
    );
  }

  Widget? _buildHandle(BuildContext context, double trackHeight) {
    final controller = widget.controller;
    if (!controller.hasClients) return null;
    final position = controller.position;
    if (!position.hasContentDimensions ||
        position.maxScrollExtent < position.viewportDimension * 2) {
      return null;
    }

    final colors = Theme.of(context).colorScheme;
    final fraction = _dragging
        ? _dragFraction
        : (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
    final top = fraction * (trackHeight - _handleHeight);
    final shown = _visible || _dragging;
    final label = _dragging ? widget.labelBuilder?.call() : null;

    return Stack(
      children: [
        PositionedDirectional(
          end: 0,
          top: top,
          width: _handleWidth,
          height: _handleHeight,
          child: IgnorePointer(
            ignoring: !shown,
            child: AnimatedOpacity(
              opacity: shown ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: ExcludeSemantics(
                child: GestureDetector(
                  key: const ValueKey('fastScrollHandle'),
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (details) {
                    _hideTimer?.cancel();
                    setState(() => _dragging = true);
                    _dragTo(details.globalPosition, trackHeight);
                  },
                  onVerticalDragUpdate: (details) =>
                      _dragTo(details.globalPosition, trackHeight),
                  onVerticalDragEnd: (_) => _endDrag(),
                  onVerticalDragCancel: _endDrag,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _dragging ? 10 : 6,
                      height: _handleHeight - 12,
                      decoration: BoxDecoration(
                        color: _dragging
                            ? colors.primary
                            : colors.onSurfaceVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (label != null)
          PositionedDirectional(
            end: _handleWidth + 8,
            top: (top + _handleHeight / 2 - 24).clamp(0.0, trackHeight - 48),
            child: ExcludeSemantics(
              child: Material(
                key: const ValueKey('fastScrollLabel'),
                color: colors.primaryContainer,
                elevation: 2,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _endDrag() {
    setState(() => _dragging = false);
    _scheduleHide();
  }
}
