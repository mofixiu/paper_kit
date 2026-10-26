import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A card of paper taped to the page with a strip of washi tape. It sits a little
/// crooked and straightens up when you hover or press it.
class PaperNote extends StatefulWidget {
  /// A note holding [child].
  const PaperNote({
    super.key,
    required this.child,
    this.rotation = -0.026,
    this.tape,
    this.padding = const EdgeInsets.fromLTRB(20, 26, 20, 20),
  });

  /// What's on the card.
  final Widget child;

  /// How crooked it sits, in radians.
  final double rotation;

  /// The tape's colour. Defaults to the palette's accent.
  final Color? tape;

  /// Space around [child].
  final EdgeInsets padding;

  @override
  State<PaperNote> createState() => _PaperNoteState();
}

class _PaperNoteState extends State<PaperNote> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    final lifted = _hovered || _pressed;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: lifted ? 1 : 0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          builder: (context, t, child) => Transform.translate(
            offset: Offset(0, -4 * t),
            child: Transform.rotate(
              angle: widget.rotation * (1 - t),
              child: child,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: p.sheet,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: p.isDark
                          ? const Color(0xB3000000)
                          : const Color(0x59281A0E),
                      blurRadius: 20,
                      spreadRadius: -12,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: widget.padding,
                  child: DefaultTextStyle.merge(
                    style: theme.text(size: 15),
                    child: widget.child,
                  ),
                ),
              ),
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: -0.07,
                    child: CustomPaint(
                      size: const Size(64, 20),
                      painter: _TapePainter(widget.tape ?? p.accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapePainter extends CustomPainter {
  const _TapePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Short edges torn into small teeth.
    final random = math.Random(5);
    final path = Path()..moveTo(0, 0);
    path.lineTo(size.width, 0);
    for (var y = 0.0; y < size.height; y += 3) {
      path.lineTo(size.width - 1.5 * random.nextDouble(), y + 1.5);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    for (var y = size.height; y > 0; y -= 3) {
      path.lineTo(1.5 * random.nextDouble(), y - 1.5);
    }
    path.close();

    canvas
      ..save()
      ..clipPath(path)
      ..drawRect(
        Offset.zero & size,
        Paint()..color = color.withValues(alpha: 0.55),
      );
    final stripe = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.16)
      ..strokeWidth = 2.5;
    for (var x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TapePainter oldDelegate) => oldDelegate.color != color;
}
