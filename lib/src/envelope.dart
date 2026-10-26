import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'motion.dart';
import 'theme.dart';

/// A sealed envelope. Tapping it cracks the wax seal, swings the flap open and
/// slides the letter out; tapping again puts the letter back.
class PaperEnvelope extends StatefulWidget {
  /// An envelope holding [letter].
  const PaperEnvelope({
    super.key,
    required this.letter,
    this.to,
    this.seal,
    this.width = 300,
    this.onOpened,
    this.onClosed,
  });

  /// What's written on the letter inside.
  final Widget letter;

  /// Who it's addressed to, written on the front.
  final String? to;

  /// The wax's colour. Defaults to a deep red.
  final Color? seal;

  /// The envelope's width. It is 0.62 times as tall, plus room above for the letter.
  final double width;

  /// Called once the letter is all the way out.
  final VoidCallback? onOpened;

  /// Called once the letter is back in.
  final VoidCallback? onClosed;

  @override
  State<PaperEnvelope> createState() => PaperEnvelopeState();
}

/// The state of a [PaperEnvelope], for opening and closing it from code.
class PaperEnvelopeState extends State<PaperEnvelope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// Whether the letter is out, or on its way out.
  bool get isOpen =>
      _controller.status == AnimationStatus.forward ||
      _controller.status == AnimationStatus.completed;

  /// Cracks the seal and takes the letter out.
  Future<void> open() async {
    if (_controller.value == 0) PaperHaptics.crack();
    await _controller.forward();
    if (mounted) widget.onOpened?.call();
  }

  /// Puts the letter back. The seal stays broken: it's been opened.
  Future<void> close() async {
    await _controller.reverse();
    if (mounted) widget.onClosed?.call();
  }

  void _toggle() => isOpen ? close() : open();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static double _phase(double t, double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    final w = widget.width;
    final h = w * 0.62;
    final rise = h * 0.72;
    final flapDepth = h * 0.56;
    final wax = widget.seal ??
        (p.isDark ? const Color(0xFFB4402F) : const Color(0xFF8E2A1E));

    return Semantics(
      button: true,
      label: isOpen ? 'Put the letter back' : 'Open the envelope',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: SizedBox(
          width: w,
          height: h + rise,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final crack = _phase(t, 0, 0.16);
              final flapT = PaperMotion.inOut.transform(_phase(t, 0.08, 0.5));
              final angle = flapT * math.pi;
              final out = PaperMotion.fadeUp.transform(_phase(t, 0.45, 1));
              final flapBehind = angle > math.pi / 2;

              final back = Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(p.sheet, p.accent, 0.16),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: p.isDark
                            ? const Color(0x99000000)
                            : const Color(0x40281A0E),
                        blurRadius: 24,
                        spreadRadius: -10,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                ),
              );

              final letter = Positioned(
                left: w * 0.06,
                right: w * 0.06,
                bottom: h * 0.06 + rise * out,
                height: h * 0.9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.sheet,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x22000000),
                        blurRadius: 6 + 10 * out,
                        offset: Offset(0, 2 + 4 * out),
                      ),
                    ],
                  ),
                  child: ClipRect(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                      child: DefaultTextStyle.merge(
                        style: theme.text(size: 14, height: 1.5),
                        child: widget.letter,
                      ),
                    ),
                  ),
                ),
              );

              final pocket = Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: h,
                child: CustomPaint(
                  painter: _PocketPainter(
                    paper: p.sheet,
                    crease: p.isDark
                        ? const Color(0x33000000)
                        : const Color(0x1A281A0E),
                    flapDepth: flapDepth / h,
                  ),
                  child: widget.to == null
                      ? null
                      : Align(
                          alignment: const Alignment(0.35, 0.62),
                          child: Text(
                            widget.to!,
                            style: theme.text(
                              size: 15,
                              weight: FontWeight.w600,
                              color: p.blueInk,
                            ),
                          ),
                        ),
                ),
              );

              final flap = Positioned(
                left: 0,
                right: 0,
                top: rise,
                height: flapDepth,
                child: Transform(
                  alignment: Alignment.topCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0016)
                    ..rotateX(-angle),
                  child: CustomPaint(
                    painter: _FlapPainter(
                      outside: Color.lerp(p.sheet, p.accent, 0.06)!,
                      inside: Color.lerp(p.sheet, p.accent, 0.3)!,
                      showInside: flapBehind,
                      shade: p.isDark
                          ? const Color(0x40000000)
                          : const Color(0x22281A0E),
                    ),
                  ),
                ),
              );

              final seal = Positioned(
                left: w / 2 - w * 0.08,
                top: rise + flapDepth - w * 0.08,
                width: w * 0.16,
                height: w * 0.16,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SealPainter(wax: wax, crack: crack),
                  ),
                ),
              );

              return Stack(
                clipBehavior: Clip.none,
                children: flapBehind
                    ? [back, flap, letter, pocket, seal]
                    : [back, letter, pocket, flap, seal],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PocketPainter extends CustomPainter {
  _PocketPainter({
    required this.paper,
    required this.crease,
    required this.flapDepth,
  });

  final Color paper;
  final Color crease;
  final double flapDepth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final meet = Offset(w / 2, h * (flapDepth - 0.06));
    final pocket = Path()
      ..moveTo(0, 0)
      ..lineTo(meet.dx, meet.dy)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(pocket, Paint()..color = paper);
    final line = Paint()
      ..color = crease
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, h), meet, line);
    canvas.drawLine(Offset(w, h), meet, line);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(meet.dx, meet.dy)
        ..lineTo(w, 0),
      line..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PocketPainter old) =>
      old.paper != paper || old.crease != crease || old.flapDepth != flapDepth;
}

class _FlapPainter extends CustomPainter {
  _FlapPainter({
    required this.outside,
    required this.inside,
    required this.showInside,
    required this.shade,
  });

  final Color outside;
  final Color inside;
  final bool showInside;
  final Color shade;

  @override
  void paint(Canvas canvas, Size size) {
    final flap = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawShadow(flap, const Color(0xFF000000), 2, false);
    canvas.drawPath(flap, Paint()..color = showInside ? inside : outside);
    if (showInside) {
      canvas.save();
      canvas.clipPath(flap);
      final liner = Paint()
        ..color = shade
        ..strokeWidth = 1;
      for (var x = -size.height; x < size.width; x += 7) {
        canvas.drawLine(
            Offset(x, 0), Offset(x + size.height, size.height), liner);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FlapPainter old) =>
      old.outside != outside ||
      old.inside != inside ||
      old.showInside != showInside ||
      old.shade != shade;
}

class _SealPainter extends CustomPainter {
  _SealPainter({required this.wax, required this.crack});

  final Color wax;
  final double crack;

  Path _blob(Size size) {
    final random = math.Random(41);
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path();
    const points = 18;
    for (var i = 0; i <= points; i++) {
      final a = i / points * math.pi * 2;
      final radius = r * (0.86 + random.nextDouble() * 0.14);
      final point = c + Offset(math.cos(a), math.sin(a)) * radius;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  void _paintWax(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final blob = _blob(size);
    canvas.drawShadow(blob, const Color(0xFF000000), 2.5, false);
    canvas.drawPath(blob, Paint()..color = wax);
    final dark = Color.lerp(wax, const Color(0xFF000000), 0.28)!;
    final light = Color.lerp(wax, const Color(0xFFFFFFFF), 0.18)!;
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08,
    );
    final s = r * 0.34;
    final heart = Path()
      ..moveTo(c.dx, c.dy + s * 0.9)
      ..cubicTo(c.dx - s * 1.4, c.dy - s * 0.1, c.dx - s * 0.6, c.dy - s * 1.1,
          c.dx, c.dy - s * 0.35)
      ..cubicTo(c.dx + s * 0.6, c.dy - s * 1.1, c.dx + s * 1.4, c.dy - s * 0.1,
          c.dx, c.dy + s * 0.9)
      ..close();
    canvas.drawPath(heart.shift(const Offset(0, -0.8)), Paint()..color = light);
    canvas.drawPath(heart, Paint()..color = dark);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (crack == 0) {
      _paintWax(canvas, size);
      return;
    }
    final opacity = (1 - crack * 1.4).clamp(0.0, 1.0);
    if (opacity == 0) return;
    final half = size.width / 2;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(half + side * crack * 6, half + crack * 10);
      canvas.rotate(side * crack * 0.5);
      canvas.translate(-half, -half);
      canvas.clipPath(Path()
        ..moveTo(half, 0)
        ..lineTo(half - 2, half * 0.6)
        ..lineTo(half + 2, half * 1.1)
        ..lineTo(half, size.height)
        ..lineTo(side < 0 ? 0 : size.width, size.height)
        ..lineTo(side < 0 ? 0 : size.width, 0)
        ..close());
      canvas.saveLayer(Offset.zero & size,
          Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
      _paintWax(canvas, size);
      canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SealPainter old) => old.wax != wax || old.crack != crack;
}
