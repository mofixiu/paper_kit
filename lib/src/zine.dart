import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'internal/pressable.dart';
import 'motion.dart';
import 'theme.dart';

/// A concertina-folded strip of paper, like a zine. Tap the title and the panels
/// unfold one after another; tap again and they fold back up.
class PaperZine extends StatefulWidget {
  /// A zine titled [title] with [panels] folded beneath it.
  const PaperZine({
    super.key,
    required this.title,
    required this.panels,
    this.initiallyExpanded = false,
    this.panelHeight = 72,
    this.onExpansionChanged,
  });

  /// Shown on the cover in lowercase.
  final String title;

  /// The folded pages, top to bottom.
  final List<Widget> panels;

  /// Whether it starts unfolded.
  final bool initiallyExpanded;

  /// The height of each panel.
  final double panelHeight;

  /// Called when it starts to unfold (true) or fold (false).
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<PaperZine> createState() => _PaperZineState();
}

class _PaperZineState extends State<PaperZine>
    with SingleTickerProviderStateMixin {
  static const int _each = 450;
  static const int _stagger = 70;

  late bool _expanded = widget.initiallyExpanded;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _total,
      value: _expanded ? 1 : 0,
    );
  }

  Duration get _total => Duration(
        milliseconds: _each + math.max(0, widget.panels.length - 1) * _stagger,
      );

  @override
  void didUpdateWidget(PaperZine oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = _total;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    widget.onExpansionChanged?.call(_expanded);
  }

  /// How far panel [index] has unfolded, 0 to 1.
  double _open(int index) {
    final elapsed = _controller.value * _total.inMilliseconds;
    final local = ((elapsed - index * _stagger) / _each).clamp(0.0, 1.0);
    return PaperMotion.fadeUp.transform(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    final shadow = p.isDark ? const Color(0x80000000) : const Color(0x22281A0E);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.sheet,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.rule.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 18,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Pressable(
              semanticLabel: widget.title,
              expanded: _expanded,
              focusInset: 2,
              onTap: _toggle,
              builder: (context, state) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title.toLowerCase(),
                        style: theme.text(size: 16, weight: FontWeight.w700),
                      ),
                    ),
                    Transform.rotate(
                      angle: math.pi * _controller.value,
                      child: CustomPaint(
                        size: const Size(12, 8),
                        painter: _Chevron(
                          state.hovered ? p.ink : p.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < widget.panels.length; i++) _panel(i, theme),
          ],
        ),
      ),
    );
  }

  Widget _panel(int index, PaperThemeData theme) {
    final p = theme.palette;
    final angle = (1 - _open(index)) * math.pi / 2;
    final visible = math.cos(angle);
    if (visible < 0.01) return const SizedBox.shrink();
    final forward = index.isEven;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..multiply(Matrix4.rotationX(forward ? -angle : angle));
    return SizedBox(
      height: widget.panelHeight * visible,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: widget.panelHeight,
        maxHeight: widget.panelHeight,
        child: Transform(
          alignment: Alignment.topCenter,
          transform: transform,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.sheet,
              border: Border(top: BorderSide(color: p.rule)),
              borderRadius: index == widget.panels.length - 1
                  ? const BorderRadius.vertical(bottom: Radius.circular(8))
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DefaultTextStyle.merge(
                      style: theme.text(size: 14),
                      child: widget.panels[index],
                    ),
                  ),
                ),
                IgnorePointer(
                  child: ColoredBox(
                    color: const Color(0xFF000000)
                        .withValues(alpha: 0.18 * angle / (math.pi / 2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chevron extends CustomPainter {
  const _Chevron(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(1, 1)
        ..lineTo(size.width / 2, size.height - 1)
        ..lineTo(size.width - 1, 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Chevron oldDelegate) => oldDelegate.color != color;
}
