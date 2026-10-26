import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// A slider drawn as a paper ruler. Drag or tap along it; the ink caret snaps to
/// each mark with a small pop.
class PaperRuler extends StatefulWidget {
  /// A ruler from [min] to [max] with [divisions] marks between them.
  const PaperRuler({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 10,
    this.divisions = 20,
    this.label,
  })  : assert(max > min),
        assert(divisions > 0);

  /// The current value.
  final double value;

  /// Called with each new value, already snapped to a mark.
  final ValueChanged<double> onChanged;

  /// The left end.
  final double min;

  /// The right end.
  final double max;

  /// How many steps there are between [min] and [max].
  final int divisions;

  /// Formats the value shown above the caret. Defaults to trimmed decimals.
  final String Function(double value)? label;

  @override
  State<PaperRuler> createState() => _PaperRulerState();
}

class _PaperRulerState extends State<PaperRuler>
    with SingleTickerProviderStateMixin {
  static const double _inset = 14;
  static const double _strip = 44;
  static const double _head = 30;

  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1,
    );
  }

  double get _step => (widget.max - widget.min) / widget.divisions;

  @override
  void didUpdateWidget(PaperRuler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  double _snap(double value) {
    final steps = ((value - widget.min) / _step).round();
    return (widget.min + steps.clamp(0, widget.divisions) * _step)
        .clamp(widget.min, widget.max);
  }

  void _setFromDx(double dx, double width) {
    final usable = width - _inset * 2;
    final t = ((dx - _inset) / usable).clamp(0.0, 1.0);
    _set(widget.min + t * (widget.max - widget.min));
  }

  void _set(double value) {
    final snapped = _snap(value);
    if ((snapped - widget.value).abs() > 1e-9) {
      HapticFeedback.selectionClick();
      widget.onChanged(snapped);
    }
  }

  String _format(double value) {
    if (widget.label != null) return widget.label!(value);
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final value = widget.value.clamp(widget.min, widget.max);
    return Semantics(
      slider: true,
      value: _format(value),
      increasedValue: _format(_snap(value + _step)),
      decreasedValue: _format(_snap(value - _step)),
      onIncrease: () => _set(value + _step),
      onDecrease: () => _set(value - _step),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyUpEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _set(value + _step);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _set(value - _step);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
            return MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _setFromDx(d.localPosition.dx, width),
                onHorizontalDragStart: (d) =>
                    _setFromDx(d.localPosition.dx, width),
                onHorizontalDragUpdate: (d) =>
                    _setFromDx(d.localPosition.dx, width),
                child: AnimatedBuilder(
                  animation: _pop,
                  builder: (context, _) {
                    final pop =
                        1 + 0.15 * (1 - Curves.easeOut.transform(_pop.value));
                    return CustomPaint(
                      size: Size(width, _head + _strip),
                      painter: _RulerPainter(
                        theme: theme,
                        min: widget.min,
                        max: widget.max,
                        divisions: widget.divisions,
                        value: value,
                        pop: pop,
                        valueLabel: _format(value),
                        tickLabel: _format,
                        textDirection: Directionality.maybeOf(context) ??
                            TextDirection.ltr,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  const _RulerPainter({
    required this.theme,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.pop,
    required this.valueLabel,
    required this.tickLabel,
    required this.textDirection,
  });

  final PaperThemeData theme;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final double pop;
  final String valueLabel;
  final String Function(double) tickLabel;
  final TextDirection textDirection;

  static const double inset = _PaperRulerState._inset;
  static const double head = _PaperRulerState._head;

  @override
  void paint(Canvas canvas, Size size) {
    final p = theme.palette;
    final strip =
        Rect.fromLTWH(0.5, head + 0.5, size.width - 1, size.height - head - 1);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
            strip.shift(const Offset(0, 2)), const Radius.circular(3)),
        Paint()..color = p.ink.withValues(alpha: p.isDark ? 0.25 : 0.06),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(strip, const Radius.circular(3)),
        Paint()..color = p.sheet,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(strip, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = p.rule,
      );

    final usable = size.width - inset * 2;
    final tick = Paint()
      ..color = p.ink.withValues(alpha: 0.75)
      ..strokeWidth = 1;
    final step = (max - min) / divisions;
    for (var i = 0; i <= divisions; i++) {
      final x = inset + usable * i / divisions;
      final major = i % 4 == 0;
      canvas.drawLine(
        Offset(x, head + 1),
        Offset(x, head + 1 + (major ? 14 : 8)),
        tick,
      );
      if (major) {
        _text(
          canvas,
          tickLabel(min + i * step),
          theme.text(size: 10, color: p.muted, weight: FontWeight.w600),
          Offset(x, head + 18),
        );
      }
    }

    final x = inset + usable * ((value - min) / (max - min));
    canvas.drawLine(
      Offset(x, head - 4),
      Offset(x, size.height - 1),
      Paint()
        ..color = p.ink
        ..strokeWidth = 1,
    );
    canvas
      ..save()
      ..translate(x, head - 4)
      ..scale(pop);
    canvas.drawPath(
      Path()
        ..moveTo(-5, -8)
        ..lineTo(5, -8)
        ..lineTo(0, 0)
        ..close(),
      Paint()..color = p.ink,
    );
    _text(
      canvas,
      valueLabel,
      theme.text(size: 12, weight: FontWeight.w700),
      const Offset(0, -24),
    );
    canvas.restore();
  }

  void _text(Canvas canvas, String text, TextStyle style, Offset topCentre) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
    )..layout();
    painter.paint(canvas, topCentre - Offset(painter.width / 2, 0));
    painter.dispose();
  }

  @override
  bool shouldRepaint(_RulerPainter oldDelegate) =>
      oldDelegate.theme != theme ||
      oldDelegate.min != min ||
      oldDelegate.max != max ||
      oldDelegate.divisions != divisions ||
      oldDelegate.value != value ||
      oldDelegate.pop != pop ||
      oldDelegate.valueLabel != valueLabel;
}
