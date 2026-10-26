import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'theme.dart';

/// Text blacked out with a marker, line by line. Tap it to lift the ink off and
/// read it; tap again to black it out.
class PaperRedact extends StatefulWidget {
  /// Redacts [text].
  const PaperRedact(
    this.text, {
    super.key,
    this.redacted = true,
    this.onChanged,
    this.style,
  });

  /// The words under the marker.
  final String text;

  /// Whether it starts blacked out.
  final bool redacted;

  /// Called after each tap with whether it's now blacked out.
  final ValueChanged<bool>? onChanged;

  /// The text style. Defaults to the kit's 16px body text.
  final TextStyle? style;

  @override
  State<PaperRedact> createState() => PaperRedactState();
}

/// The state of a [PaperRedact].
class PaperRedactState extends State<PaperRedact>
    with SingleTickerProviderStateMixin {
  late final AnimationController _marker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: widget.redacted ? 1 : 0,
  );

  /// Whether the text is blacked out (or being).
  bool get isRedacted =>
      _marker.status == AnimationStatus.forward ||
      _marker.status == AnimationStatus.completed;

  /// Blacks it out, or lifts the ink off.
  void toggle() {
    final redact = !isRedacted;
    PaperHaptics.stroke();
    redact ? _marker.forward() : _marker.reverse();
    widget.onChanged?.call(redact);
  }

  @override
  void dispose() {
    _marker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final style = theme.text(size: 16, height: 1.6).merge(widget.style);
    return Semantics(
      button: true,
      label: isRedacted ? 'Redacted text. Tap to reveal.' : widget.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(toggle),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(text: widget.text, style: style),
              textDirection: Directionality.of(context),
            )..layout(maxWidth: constraints.maxWidth);
            final lines = painter.computeLineMetrics();
            return CustomPaint(
              foregroundPainter: _BarPainter(
                progress: _marker,
                lines: lines,
                ink: theme.isDark
                    ? const Color(0xFF050505)
                    : const Color(0xFF16130F),
              ),
              child: ExcludeSemantics(
                child: Text(widget.text, style: style),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.progress,
    required this.lines,
    required this.ink,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final List<ui.LineMetrics> lines;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (lines.isEmpty || progress.value == 0) return;
    final paint = Paint()..color = ink;
    // One marker stroke per line, each starting when the one above is done.
    final share = 1 / lines.length;
    for (var i = 0; i < lines.length; i++) {
      final t = ((progress.value - i * share) / share).clamp(0.0, 1.0);
      if (t == 0) continue;
      final line = lines[i];
      final random = math.Random(i * 31 + 7);
      final top = line.baseline - line.ascent - 1;
      final bottom = line.baseline + line.descent + 1;
      final left = line.left - 3;
      final right = left + (line.width + 6) * Curves.easeOut.transform(t);
      final bar = Path()..moveTo(left, top + 1.5);
      for (var x = left + 6; x < right; x += 7) {
        bar.lineTo(x, top + random.nextDouble() * 1.8);
      }
      bar
        ..lineTo(right, top + 1)
        ..lineTo(right + 1.5, (top + bottom) / 2)
        ..lineTo(right, bottom - 1);
      for (var x = right - 6; x > left; x -= 7) {
        bar.lineTo(x, bottom - random.nextDouble() * 1.8);
      }
      bar
        ..lineTo(left, bottom - 1.5)
        ..close();
      canvas.drawPath(bar, paint);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.lines != lines || old.ink != ink;
}
