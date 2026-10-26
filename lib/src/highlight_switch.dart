import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'theme.dart';

/// A switch that is a highlighter: turning it on drags a streaky marker stroke
/// across its label, turning it off lifts the ink back off the page.
class PaperHighlightSwitch extends StatefulWidget {
  /// A switch labelled [label].
  const PaperHighlightSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.ink,
  });

  /// The words that get highlighted.
  final String label;

  /// Whether it's on.
  final bool value;

  /// Called with the new value when tapped.
  final ValueChanged<bool> onChanged;

  /// The highlighter's colour. Defaults to highlighter yellow.
  final Color? ink;

  @override
  State<PaperHighlightSwitch> createState() => _PaperHighlightSwitchState();
}

class _PaperHighlightSwitchState extends State<PaperHighlightSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stroke = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 200),
    value: widget.value ? 1 : 0,
  );

  @override
  void didUpdateWidget(PaperHighlightSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      widget.value ? _stroke.forward() : _stroke.reverse();
    }
  }

  @override
  void dispose() {
    _stroke.dispose();
    super.dispose();
  }

  void _toggle() {
    PaperHaptics.stroke();
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    final ink = widget.ink ??
        (p.isDark ? const Color(0xFFD9BC3F) : const Color(0xFFF2CF3A));
    return Semantics(
      toggled: widget.value,
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: CustomPaint(
            painter: _MarkerPainter(
              progress: _stroke,
              ink: ink,
              strength: p.isDark ? 0.34 : 0.62,
              // Multiply on cream, the way ink sinks into paper; it would vanish on dark.
              blend: p.isDark ? BlendMode.srcOver : BlendMode.multiply,
              seed: widget.label.length,
            ),
            child: ExcludeSemantics(
              child: Text(
                widget.label,
                style: theme.text(size: 16, weight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter({
    required this.progress,
    required this.ink,
    required this.strength,
    required this.seed,
    required this.blend,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color ink;
  final double strength;
  final int seed;
  final BlendMode blend;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(progress.value);
    if (t == 0) return;
    final random = math.Random(seed);
    final top = size.height * 0.24;
    final bottom = size.height * 0.98;
    final end = -4 + (size.width + 10) * t;
    // A chisel tip: slanted ends, edges that wander a little.
    final band = Path()..moveTo(-2, top + 2);
    for (var x = 4.0; x < end; x += 9) {
      band.lineTo(x, top + random.nextDouble() * 2.2);
    }
    band
      ..lineTo(end + 3, top + 1)
      ..lineTo(end - 2, bottom);
    for (var x = end - 8; x > -4; x -= 9) {
      band.lineTo(x, bottom - random.nextDouble() * 2.2);
    }
    band
      ..lineTo(-6, bottom - 1)
      ..close();
    canvas.drawPath(
      band,
      Paint()
        ..color = ink.withValues(alpha: strength)
        ..blendMode = blend,
    );
    // Streaks where the felt tip ran drier.
    final streak = Paint()
      ..color = ink.withValues(alpha: strength * 0.5)
      ..strokeWidth = 1.2
      ..blendMode = blend;
    for (final y in [0.38, 0.62, 0.84]) {
      final h = top + (bottom - top) * y;
      canvas.drawLine(Offset(0, h), Offset(end - 4, h + 0.6), streak);
    }
  }

  @override
  bool shouldRepaint(_MarkerPainter old) =>
      old.ink != ink ||
      old.strength != strength ||
      old.seed != seed ||
      old.blend != blend;
}
