import 'package:flutter/widgets.dart';

import 'internal/pressable.dart';
import 'internal/rough.dart';
import 'theme.dart';

/// A hand-drawn box that gets a scribbled blue tick, and crosses out its label.
class PaperCheckbox extends StatefulWidget {
  /// A checkbox showing [value].
  const PaperCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.strike = true,
  });

  /// Whether it's ticked.
  final bool value;

  /// Called with the new value when tapped.
  final ValueChanged<bool> onChanged;

  /// Text beside the box. Tapping it toggles the box too.
  final String? label;

  /// Whether a ticked label is crossed out and faded.
  final bool strike;

  @override
  State<PaperCheckbox> createState() => _PaperCheckboxState();
}

class _PaperCheckboxState extends State<PaperCheckbox>
    with TickerProviderStateMixin {
  late final AnimationController _tick;
  late final AnimationController _strike;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 160),
      value: widget.value ? 1 : 0,
    );
    _strike = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.value ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(PaperCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _tick.forward();
        _strike.forward();
      } else {
        _tick.reverse();
        _strike.reverse();
      }
    }
  }

  @override
  void dispose() {
    _tick.dispose();
    _strike.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final palette = theme.palette;
    final seed = (widget.label ?? '').hashCode & 0xffff;
    return Pressable(
      semanticLabel: widget.label,
      checked: widget.value,
      onTap: () => widget.onChanged(!widget.value),
      builder: (context, state) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _tick,
              builder: (context, _) => CustomPaint(
                size: const Size.square(22),
                painter: _BoxPainter(
                  ink: state.hovered
                      ? palette.ink
                      : palette.ink.withValues(alpha: 0.85),
                  tickColor: palette.blueInk,
                  progress: _tick.status == AnimationStatus.reverse
                      ? _tick.value
                      : Curves.easeOut.transform(_tick.value),
                  seed: seed,
                ),
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(width: 10),
              Flexible(
                child: AnimatedBuilder(
                  animation: _strike,
                  builder: (context, _) {
                    final t = widget.strike
                        ? Curves.easeOut.transform(_strike.value)
                        : 0.0;
                    return CustomPaint(
                      foregroundPainter: t > 0
                          ? _StrikePainter(
                              color: palette.ink.withValues(alpha: 0.75),
                              progress: t,
                              seed: seed,
                            )
                          : null,
                      child: Text(
                        widget.label!,
                        style: theme.text(
                          size: 15,
                          color: Color.lerp(palette.ink, palette.muted, t),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  const _BoxPainter({
    required this.ink,
    required this.tickColor,
    required this.progress,
    required this.seed,
  });

  final Color ink;
  final Color tickColor;
  final double progress;
  final int seed;

  static final Path _tickPath = Path()
    ..moveTo(4, 12)
    ..quadraticBezierTo(6.6, 14.2, 9, 17)
    ..quadraticBezierTo(13.4, 9.6, 19, 4)
    ..lineTo(20.6, 2.3);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 22, size.height / 22);
    canvas.drawPath(
      Rough.rect(
        const Rect.fromLTWH(2, 2, 18, 18),
        seed: seed,
        jitter: 0.7,
        bow: 0.8,
        overshoot: 2,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
    if (progress > 0) {
      canvas.drawPath(
        Rough.trim(_tickPath, progress),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = tickColor,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoxPainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.tickColor != tickColor ||
      oldDelegate.progress != progress ||
      oldDelegate.seed != seed;
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter({
    required this.color,
    required this.progress,
    required this.seed,
  });

  final Color color;
  final double progress;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.56;
    final line = Rough.wavyLine(
      Offset(-2, y + 0.6),
      Offset(size.width + 2, y - 0.8),
      amplitude: 0.9,
      wavelength: 22,
      phase: seed.toDouble(),
    );
    canvas.drawPath(
      Rough.trim(line, progress),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.seed != seed;
}
