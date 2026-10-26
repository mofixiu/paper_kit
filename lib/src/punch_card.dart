import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'stamp.dart';
import 'theme.dart';

/// A loyalty card you punch. Each tap goes through the next circle: the hole is
/// really cut, so whatever is under the card shows through, and the little disc
/// of paper drops out and tumbles away. Full, it gets stamped.
class PaperPunchCard extends StatefulWidget {
  /// A card with [holes] circles, [punched] of them already punched.
  const PaperPunchCard({
    super.key,
    required this.holes,
    required this.punched,
    required this.onPunch,
    this.title,
    this.reward,
    this.width = 300,
  });

  /// How many circles there are.
  final int holes;

  /// How many are punched.
  final int punched;

  /// Called with the new count after a punch. A full card ignores taps.
  final ValueChanged<int> onPunch;

  /// Written across the top.
  final String? title;

  /// Stamped on the card once every hole is punched.
  final String? reward;

  /// The card's width.
  final double width;

  @override
  State<PaperPunchCard> createState() => _PaperPunchCardState();
}

class _PaperPunchCardState extends State<PaperPunchCard>
    with TickerProviderStateMixin {
  final _chads = <_Chad>[];
  int _seed = 0;

  static const _perRow = 5;
  static const _radius = 11.0;

  Offset _hole(int index, Size card) {
    final rows = (widget.holes / _perRow).ceil();
    final row = index ~/ _perRow;
    final column = index % _perRow;
    final gap = card.width / _perRow;
    final top = card.height - rows * 40 - 6;
    return Offset(gap * (column + 0.5), top + row * 40 + 20);
  }

  void _punch(Size card) {
    if (widget.punched >= widget.holes) return;
    PaperHaptics.punch();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final chad = _Chad(_hole(widget.punched, card), _seed++, controller);
    setState(() => _chads.add(chad));
    controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _chads.remove(chad));
      controller.dispose();
    });
    widget.onPunch(widget.punched + 1);
  }

  @override
  void dispose() {
    for (final chad in _chads) {
      chad.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    final rows = (widget.holes / _perRow).ceil();
    final card = Size(widget.width, 70 + rows * 40.0 + 6);
    final full = widget.punched >= widget.holes;
    return Semantics(
      button: !full,
      label: '${widget.title ?? 'Punch card'}: '
          '${widget.punched} of ${widget.holes} punched',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _punch(card),
        child: SizedBox.fromSize(
          size: card,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: card,
                painter: _CardPainter(
                  sheet: p.sheet,
                  rim: p.rule,
                  dash: p.faint,
                  holes: [
                    for (var i = 0; i < widget.holes; i++) _hole(i, card),
                  ],
                  punched: widget.punched,
                  radius: _radius,
                  shadow: p.isDark
                      ? const Color(0x99000000)
                      : const Color(0x40281A0E),
                ),
              ),
              Positioned(
                left: 18,
                top: 16,
                right: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        (widget.title ?? '').toLowerCase(),
                        style: theme.text(size: 15, weight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${widget.punched} / ${widget.holes}',
                      style: theme.text(
                        size: 12,
                        weight: FontWeight.w700,
                        color: p.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (full && widget.reward != null)
                Positioned(
                  right: 16,
                  top: 36,
                  child: Transform.rotate(
                    angle: -0.08,
                    child: PaperStampImpression(
                      label: widget.reward!,
                      seed: widget.holes,
                    ),
                  ),
                ),
              for (final chad in _chads)
                AnimatedBuilder(
                  animation: chad.controller,
                  builder: (context, _) {
                    final t = chad.controller.value;
                    final random = math.Random(chad.seed);
                    final drift = (random.nextDouble() - 0.5) * 40;
                    return Positioned(
                      left: chad.at.dx - _radius + drift * t,
                      top: chad.at.dy - _radius + 160 * t * t,
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationZ(t * 5)
                            ..multiply(Matrix4.diagonal3Values(
                                1, math.cos(t * 9).abs() * 0.8 + 0.2, 1)),
                          child: Container(
                            width: _radius * 2,
                            height: _radius * 2,
                            decoration: BoxDecoration(
                              color: p.sheet,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.rule),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chad {
  _Chad(this.at, this.seed, this.controller);

  final Offset at;
  final int seed;
  final AnimationController controller;
}

class _CardPainter extends CustomPainter {
  _CardPainter({
    required this.sheet,
    required this.rim,
    required this.dash,
    required this.holes,
    required this.punched,
    required this.radius,
    required this.shadow,
  });

  final Color sheet;
  final Color rim;
  final Color dash;
  final List<Offset> holes;
  final int punched;
  final double radius;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final card =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    var outline = Path()..addRRect(card);
    for (final hole in holes.take(punched)) {
      outline = Path.combine(PathOperation.difference, outline,
          Path()..addOval(Rect.fromCircle(center: hole, radius: radius)));
    }
    canvas.drawShadow(outline, shadow, 5, false);
    canvas.drawPath(outline, Paint()..color = sheet);
    canvas.drawPath(
      outline,
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final dots = Paint()..color = dash;
    for (final hole in holes.skip(punched)) {
      for (var a = 0.0; a < math.pi * 2; a += math.pi / 10) {
        canvas.drawCircle(
            hole + Offset(math.cos(a), math.sin(a)) * radius, 0.9, dots);
      }
    }
  }

  @override
  bool shouldRepaint(_CardPainter old) =>
      old.punched != punched ||
      old.sheet != sheet ||
      old.rim != rim ||
      old.holes.length != holes.length;
}
