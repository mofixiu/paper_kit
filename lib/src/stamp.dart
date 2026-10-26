import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'internal/pressable.dart';
import 'internal/rough.dart';
import 'theme.dart';

/// The mark a rubber stamp leaves: [label] inside a rough double frame, with the
/// uneven ink and tiny gaps of a real impression.
///
/// [PaperStampButton] and [PaperTearToConfirm] leave these behind; you can also
/// place one yourself.
class PaperStampImpression extends StatelessWidget {
  /// An impression of [label].
  const PaperStampImpression({
    super.key,
    required this.label,
    this.color,
    this.seed = 0,
    this.fontSize = 14,
    this.opacity = 0.9,
  });

  /// The stamped word. It is shown in lowercase.
  final String label;

  /// The ink. Defaults to the palette's red pen.
  final Color? color;

  /// Picks the pattern of gaps and wobbles, so each impression looks different.
  final int seed;

  /// The size of the lettering.
  final double fontSize;

  /// How strongly the ink took.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final style = theme.text(
      size: fontSize,
      weight: FontWeight.w800,
      letterSpacing: fontSize * 0.086,
      color: color ?? theme.palette.redPen,
    );
    final text = label.toLowerCase();
    return Semantics(
      label: text,
      child: CustomPaint(
        painter: _ImpressionPainter(
          text: text,
          style: style,
          seed: seed,
          opacity: opacity,
          multiply: !theme.isDark,
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        ),
        child: ExcludeSemantics(
          child: Opacity(
            opacity: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: fontSize * 1.57,
                vertical: fontSize,
              ),
              child: Text(text, style: style),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImpressionPainter extends CustomPainter {
  const _ImpressionPainter({
    required this.text,
    required this.style,
    required this.seed,
    required this.opacity,
    required this.multiply,
    required this.textDirection,
  });

  final String text;
  final TextStyle style;
  final int seed;
  final double opacity;
  final bool multiply;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || size.isEmpty) return;
    final color = style.color!;
    final bounds = Offset.zero & size;
    canvas.saveLayer(
      bounds.inflate(6),
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0))
        ..blendMode = multiply ? BlendMode.multiply : BlendMode.srcOver,
    );

    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas
      ..drawPath(
        Rough.rect(bounds.deflate(1.5), seed: seed, jitter: 1.1, bow: 0.9),
        ink..strokeWidth = 2.4,
      )
      ..drawPath(
        Rough.rect(bounds.deflate(5.5), seed: seed + 1, jitter: 0.8),
        ink..strokeWidth = 1.1,
      );

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      bounds.center - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();

    // Where the ink didn't take: specks, a few scratches and one faint patch.
    final random = math.Random(seed * 977 + 13);
    final gap = Paint()..blendMode = BlendMode.dstOut;
    for (var i = 0; i < (size.width * size.height / 70).round(); i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawCircle(
        point,
        0.35 + random.nextDouble() * 1.1,
        gap..color = Color.fromRGBO(0, 0, 0, 0.55 + random.nextDouble() * 0.45),
      );
    }
    final scratch = Paint()
      ..blendMode = BlendMode.dstOut
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.8;
    for (var i = 0; i < 6; i++) {
      final start = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final length = 3 + random.nextDouble() * 7;
      final angle = (random.nextDouble() - 0.5) * 0.6;
      canvas.drawLine(
        start,
        start + Offset(math.cos(angle), math.sin(angle)) * length,
        scratch..color = const Color(0xCC000000),
      );
    }
    final patch = Offset(
      random.nextDouble() * size.width,
      random.nextDouble() * size.height,
    );
    final patchRadius = size.shortestSide * (0.6 + random.nextDouble() * 0.5);
    canvas
      ..drawCircle(
        patch,
        patchRadius,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..shader = const RadialGradient(
            colors: [Color(0x66000000), Color(0x00000000)],
          ).createShader(
            Rect.fromCircle(center: patch, radius: patchRadius),
          ),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_ImpressionPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.seed != seed ||
      oldDelegate.opacity != opacity ||
      oldDelegate.multiply != multiply;
}

/// A rubber stamp. Pressing it pushes it down, and lifting it leaves a red
/// impression of its label on the paper that slowly fades.
class PaperStampButton extends StatefulWidget {
  /// A stamp reading [label].
  const PaperStampButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.ink,
  });

  /// The word on the stamp. It is shown in lowercase.
  final String label;

  /// Called on every stamp.
  final VoidCallback onPressed;

  /// The colour of the stamp's border and lettering. Defaults to the palette's ink.
  final Color? ink;

  @override
  State<PaperStampButton> createState() => _PaperStampButtonState();
}

class _Impression {
  _Impression(this.seed, this.rotation, this.controller);

  final int seed;
  final double rotation;
  final AnimationController controller;
}

class _PaperStampButtonState extends State<PaperStampButton>
    with TickerProviderStateMixin {
  static const _slam = 120;
  static const _fade = 1200;
  final _impressions = <_Impression>[];
  int _seed = 0;

  void _stamp() {
    final seed = _seed++;
    final random = math.Random(seed * 7919 + widget.label.hashCode);
    final rotation = (random.nextDouble() * 12 - 6) * math.pi / 180;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _slam + _fade),
    );
    final impression = _Impression(seed, rotation, controller);
    setState(() => _impressions.add(impression));
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _impressions.remove(impression));
      controller.dispose();
    });
    widget.onPressed();
  }

  @override
  void dispose() {
    for (final impression in _impressions) {
      impression.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final ink = widget.ink ?? theme.palette.ink;
    final label = widget.label.toLowerCase();
    final button = Pressable(
      semanticLabel: label,
      focusInset: -4,
      onTap: _stamp,
      builder: (context, state) => AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        transformAlignment: Alignment.center,
        transform: state.pressed
            ? (Matrix4.translationValues(0, 2, 0)
              ..multiply(Matrix4.diagonal3Values(0.97, 0.97, 1)))
            : Matrix4.identity(),
        child: CustomPaint(
          painter: _StampBodyPainter(
            fill: theme.palette.sheet,
            ink: ink,
            pressed: state.pressed,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            child: Text(
              label,
              style: theme.text(
                size: 14,
                weight: FontWeight.w800,
                letterSpacing: 1.2,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        for (final impression in _impressions)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: impression.controller,
                builder: (context, child) {
                  final t =
                      impression.controller.value * (_slam + _fade) / _slam;
                  final slam = Curves.easeOut.transform(t.clamp(0.0, 1.0));
                  final fade =
                      ((impression.controller.value * (_slam + _fade) - _slam) /
                              _fade)
                          .clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: const Offset(8, 6),
                    child: Transform.rotate(
                      angle: impression.rotation,
                      child: Transform.scale(
                        scale: 1.18 - 0.18 * slam,
                        child: PaperStampImpression(
                          label: label,
                          seed: impression.seed,
                          opacity: 0.9 * (1 - Curves.easeIn.transform(fade)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _StampBodyPainter extends CustomPainter {
  const _StampBodyPainter({
    required this.fill,
    required this.ink,
    required this.pressed,
  });

  final Color fill;
  final Color ink;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      const Radius.circular(4),
    );
    if (!pressed) {
      canvas.drawRRect(
        outer.shift(const Offset(0, 2)),
        Paint()..color = ink.withValues(alpha: 0.18),
      );
    }
    canvas
      ..drawRRect(outer, Paint()..color = fill)
      ..drawRRect(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ink,
      )
      ..drawRRect(
        outer.deflate(4.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = ink,
      );
  }

  @override
  bool shouldRepaint(_StampBodyPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.ink != ink ||
      oldDelegate.pressed != pressed;
}
