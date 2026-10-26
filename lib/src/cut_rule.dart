import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'theme.dart';

/// A dashed "cut here" line with a pair of scissors. Drag the scissors along it,
/// or tap them to cut in one go; once they reach the end, the coupon underneath
/// comes away.
class PaperCutRule extends StatefulWidget {
  /// A cut line above [child].
  const PaperCutRule({
    super.key,
    required this.child,
    this.label = 'cut here',
    this.onCut,
  });

  /// The coupon below the line.
  final Widget child;

  /// Printed at the end of the line.
  final String label;

  /// Called once the coupon has come away.
  final VoidCallback? onCut;

  @override
  State<PaperCutRule> createState() => PaperCutRuleState();
}

/// The state of a [PaperCutRule].
class PaperCutRuleState extends State<PaperCutRule>
    with TickerProviderStateMixin {
  late final AnimationController _cut = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..addListener(_snip);
  late final AnimationController _away = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  double _width = 1;
  int _snips = 0;

  /// Whether the coupon has been cut off.
  bool get isCut => _away.value > 0;

  void _snip() {
    // One snip every 18px of travel.
    final snips = (_cut.value * _width / 18).floor();
    if (snips != _snips) {
      _snips = snips;
      PaperHaptics.snip();
    }
  }

  Future<void> _finish() async {
    await _away.forward();
    widget.onCut?.call();
  }

  /// Cuts all the way along.
  Future<void> cut() async {
    if (isCut) return;
    await _cut.animateTo(1, curve: Curves.easeInOut);
    await _finish();
  }

  /// Puts a fresh coupon back.
  void reset() {
    _cut.value = 0;
    _away.value = 0;
    _snips = 0;
  }

  void _drag(double dx) {
    if (isCut) return;
    _cut.value = (_cut.value + dx / _width).clamp(_cut.value, 1.0);
    if (_cut.value >= 0.96) {
      _cut.value = 1;
      _finish();
    }
  }

  @override
  void dispose() {
    _cut.dispose();
    _away.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth.isFinite ? constraints.maxWidth : 300;
        return AnimatedBuilder(
          animation: Listenable.merge([_cut, _away]),
          builder: (context, _) {
            final away = Curves.easeIn.transform(_away.value);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  label:
                      '${widget.label}: drag the scissors along, or tap them',
                  onTap: cut,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: cut,
                    onHorizontalDragUpdate: (details) =>
                        _drag(details.delta.dx),
                    child: SizedBox(
                      height: 34,
                      child: CustomPaint(
                        painter: _RulePainter(
                          progress: _cut.value,
                          dash: p.muted,
                          ink: p.ink,
                          label: widget.label,
                          labelStyle: theme.text(
                            size: 10,
                            weight: FontWeight.w700,
                            color: p.faint,
                            letterSpacing: 1.4,
                          ),
                          visible: away < 1,
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(10 * away, 34 * away),
                  child: Transform.rotate(
                    angle: 0.06 * away,
                    alignment: Alignment.topLeft,
                    child: Opacity(
                      opacity: 1 - away,
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RulePainter extends CustomPainter {
  _RulePainter({
    required this.progress,
    required this.dash,
    required this.ink,
    required this.label,
    required this.labelStyle,
    required this.visible,
  });

  final double progress;
  final Color dash;
  final Color ink;
  final String label;
  final TextStyle labelStyle;
  final bool visible;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - 8;
    final x = 12 + (size.width - 24) * progress;
    final line = Paint()
      ..color = dash
      ..strokeWidth = 1.4;
    // Still to cut: dashes. Already cut: a thin ragged gap.
    for (var d = x; d < size.width; d += 9) {
      canvas.drawLine(
          Offset(d, y), Offset(math.min(d + 5, size.width), y), line);
    }
    final gap = Paint()
      ..color = dash.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    for (var d = 0.0; d < x; d += 3) {
      final wobble = math.sin(d * 1.7) * 0.6;
      canvas.drawLine(
          Offset(d, y - 1 + wobble), Offset(d + 3, y - 1 - wobble), gap);
      canvas.drawLine(
          Offset(d, y + 1 + wobble), Offset(d + 3, y + 1 - wobble), gap);
    }
    final text = TextPainter(
      text: TextSpan(text: label.toUpperCase(), style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(size.width - text.width, y - text.height - 6));
    if (visible) _scissors(canvas, Offset(x, y), (x / 9) % 2 < 1 ? 0.32 : 0.08);
  }

  // Two blades on a pivot, opening and closing as they travel.
  void _scissors(Canvas canvas, Offset at, double open) {
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = ink;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(1.5);
      canvas.rotate(side * open);
      final blade = Path()
        ..moveTo(0, 0)
        ..lineTo(14, side * 1.2)
        ..lineTo(0, side * 2.6)
        ..close();
      canvas.drawPath(blade, fill);
      canvas.drawLine(Offset.zero, Offset(-7, side * 4), stroke);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(-11, side * 6), width: 9, height: 7),
          stroke);
      canvas.restore();
    }
    canvas.drawCircle(at, 1.6, Paint()..color = const Color(0xFFB8B4AC));
  }

  @override
  bool shouldRepaint(_RulePainter old) =>
      old.progress != progress ||
      old.visible != visible ||
      old.dash != dash ||
      old.ink != ink;
}
