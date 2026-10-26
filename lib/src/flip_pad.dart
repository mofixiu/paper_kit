import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'theme.dart';

/// A wire-bound pad, like a desk calendar. Tap or swipe up and the page flips
/// over the rings; swipe down to bring the last one back.
class PaperFlipPad extends StatefulWidget {
  /// A pad of [pages], the first on top.
  const PaperFlipPad({
    super.key,
    required this.pages,
    this.size = const Size(280, 190),
    this.onPageChanged,
  });

  /// The pages, in order. There must be at least one.
  final List<Widget> pages;

  /// The size of a page, not counting the wire binding above it.
  final Size size;

  /// Called with the new page's index after each flip.
  final ValueChanged<int>? onPageChanged;

  @override
  State<PaperFlipPad> createState() => PaperFlipPadState();
}

/// The state of a [PaperFlipPad].
class PaperFlipPadState extends State<PaperFlipPad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  int _page = 0;

  /// The page on top.
  int get page => _page;

  /// Flips the top page over. On the last page it does nothing.
  Future<void> next() async {
    if (_flip.isAnimating || _page >= widget.pages.length - 1) return;
    PaperHaptics.flip();
    await _flip.forward(from: 0);
    setState(() => _page++);
    _flip.value = 0;
    widget.onPageChanged?.call(_page);
  }

  /// Brings the page before back over the rings.
  Future<void> previous() async {
    if (_flip.isAnimating || _page == 0) return;
    PaperHaptics.flip();
    setState(() => _page--);
    await _flip.reverse(from: 1);
    widget.onPageChanged?.call(_page);
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    final size = widget.size;
    const binding = 22.0;

    Widget sheet(int index, {bool back = false}) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: back ? Color.lerp(p.sheet, p.paper, 0.6) : p.sheet,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
        ),
        child: back
            ? CustomPaint(painter: _RulePainter(p.rule))
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                child: DefaultTextStyle.merge(
                  style: theme.text(size: 14),
                  child: Stack(
                    children: [
                      Positioned.fill(child: widget.pages[index]),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Text(
                          '${index + 1} / ${widget.pages.length}',
                          style: theme.text(
                              size: 11,
                              weight: FontWeight.w700,
                              color: p.faint),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    return Semantics(
      label: 'Page ${_page + 1} of ${widget.pages.length}',
      onIncrease: next,
      onDecrease: previous,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: next,
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -80) next();
          if (velocity > 80) previous();
        },
        child: SizedBox(
          width: size.width,
          height: size.height + binding,
          child: AnimatedBuilder(
            animation: _flip,
            builder: (context, _) {
              final t = Curves.easeInOutCubic.transform(_flip.value);
              final angle = t * math.pi;
              final flipping = _flip.value > 0;
              final under = _page + 1;
              final onTop = _page;
              final shown = angle <= math.pi / 2;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: binding,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.lerp(p.accent, p.ink, 0.35),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: p.isDark
                                ? const Color(0xB3000000)
                                : const Color(0x59281A0E),
                            blurRadius: 18,
                            spreadRadius: -8,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child:
                          SizedBox(width: size.width, height: size.height + 4),
                    ),
                  ),
                  if (under < widget.pages.length)
                    Positioned(
                      left: 0,
                      top: binding,
                      child: Stack(
                        children: [
                          sheet(under),
                          if (flipping)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color.fromRGBO(
                                            0, 0, 0, 0.22 * math.sin(angle)),
                                        const Color(0x00000000),
                                      ],
                                      stops: [
                                        0,
                                        0.2 + 0.8 * math.cos(angle / 2)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Positioned(
                    left: 0,
                    top: binding,
                    child: Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0014)
                        ..rotateX(angle),
                      child: Stack(
                        children: [
                          shown ? sheet(onTop) : sheet(onTop, back: true),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ColoredBox(
                                color: Color.fromRGBO(
                                    0, 0, 0, 0.16 * math.sin(angle)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: CustomPaint(
                      size: Size(size.width, binding + 10),
                      painter: _BindingPainter(
                        wire: p.isDark
                            ? const Color(0xFFB9B4AC)
                            : const Color(0xFF6E6A64),
                        hole: p.isDark
                            ? const Color(0xFF0E0D0B)
                            : const Color(0xFF3A342C),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RulePainter extends CustomPainter {
  _RulePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var y = 30.0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RulePainter old) => old.color != color;
}

class _BindingPainter extends CustomPainter {
  _BindingPainter({required this.wire, required this.hole});

  final Color wire;
  final Color hole;

  @override
  void paint(Canvas canvas, Size size) {
    final loops = (size.width / 22).floor();
    final gap = size.width / loops;
    final top = size.height - 10;
    final holePaint = Paint()..color = hole;
    final wirePaint = Paint()
      ..color = wire
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final shine = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var i = 0; i < loops; i++) {
      final x = gap * (i + 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, top + 6), width: 7, height: 4),
          const Radius.circular(2),
        ),
        holePaint,
      );
      for (final dx in [-1.6, 1.6]) {
        final loop = Path()
          ..moveTo(x + dx, top + 6)
          ..cubicTo(x + dx, top - 8, x + dx + 2, top - 10, x + dx + 3, top - 4);
        canvas.drawPath(loop, wirePaint);
        canvas.drawPath(loop.shift(const Offset(-0.6, -0.4)), shine);
      }
    }
  }

  @override
  bool shouldRepaint(_BindingPainter old) =>
      old.wire != wire || old.hole != hole;
}
