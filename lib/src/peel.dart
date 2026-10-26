import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';

/// A square sticky note you peel off by its corner.
///
/// Drag the curled bottom-right corner and the note folds back along a real fold
/// line. Pull it past halfway and it comes away; let go sooner and it lies flat
/// again.
class PaperPeel extends StatefulWidget {
  /// A note showing [child].
  const PaperPeel({
    super.key,
    required this.child,
    this.onPeeled,
    this.color,
    this.size = 180,
  });

  /// What's written on the note.
  final Widget child;

  /// Called once the note has been peeled off.
  final VoidCallback? onPeeled;

  /// The note's colour. Defaults to the palette's sticky-note yellow.
  final Color? color;

  /// The note's width and height.
  final double size;

  @override
  PaperPeelState createState() => PaperPeelState();
}

/// The state of a [PaperPeel]. Use a `GlobalKey` to call [peel] or [reset].
class PaperPeelState extends State<PaperPeel> with TickerProviderStateMixin {
  static const double _rest = 14;
  static const double _hover = 24;

  late Offset _tip = _restTip;
  bool _dragging = false;
  bool _peeled = false;
  bool _hovered = false;

  late final AnimationController _settle;
  late final AnimationController _away;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _away = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  Offset get _corner => Offset(widget.size, widget.size);
  Offset get _restTip =>
      _corner - Offset(_hovered ? _hover : _rest, _hovered ? _hover : _rest);

  /// Whether the note has been peeled off.
  bool get isPeeled => _peeled;

  @override
  void dispose() {
    _settle.dispose();
    _away.dispose();
    super.dispose();
  }

  void _animateTip(Offset to) {
    final from = _tip;
    final animation =
        CurvedAnimation(parent: _settle, curve: PaperMotion.fadeUp);
    void listener() {
      if (mounted) {
        setState(() => _tip = Offset.lerp(from, to, animation.value)!);
      }
    }

    _settle
      ..stop()
      ..value = 0;
    animation.addListener(listener);
    _settle.forward().whenCompleteOrCancel(() {
      animation
        ..removeListener(listener)
        ..dispose();
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_peeled || _away.isAnimating) return;
    _dragging = (details.localPosition - _corner).distance < 64;
    if (_dragging) {
      _settle.stop();
      setState(() => _tip = _clampTip(details.localPosition));
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    setState(() => _tip = _clampTip(details.localPosition));
  }

  void _onPanEnd([DragEndDetails? details]) {
    if (!_dragging) return;
    _dragging = false;
    final progress = (_corner - _tip).distance / (widget.size * math.sqrt2);
    if (progress > 0.55) {
      peel();
    } else {
      _animateTip(_restTip);
    }
  }

  Offset _clampTip(Offset position) {
    final s = widget.size;
    var tip = Offset(
      position.dx.clamp(-s * 0.5, s - _rest),
      position.dy.clamp(-s * 0.5, s - _rest),
    );
    if ((_corner - tip).distance < _rest * math.sqrt2) tip = _restTip;
    return tip;
  }

  /// Peels the note off, as if pulled by its corner.
  Future<void> peel() async {
    if (_peeled || _away.isAnimating) return;
    _settle.stop();
    await _away.forward(from: 0);
    if (!mounted) return;
    setState(() => _peeled = true);
    widget.onPeeled?.call();
  }

  /// Sticks the note back down.
  void reset() {
    _away.value = 0;
    setState(() {
      _peeled = false;
      _tip = _restTip;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    final color = widget.color ?? p.note;
    final s = widget.size;
    if (_peeled) return SizedBox.square(dimension: s);
    return Semantics(
      label: 'Sticky note',
      hint: 'Drag the corner to peel it off',
      onDismiss: peel,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) {
          _hovered = true;
          if (!_dragging) _animateTip(_restTip);
        },
        onExit: (_) {
          _hovered = false;
          if (!_dragging) _animateTip(_restTip);
        },
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanEnd,
          child: AnimatedBuilder(
            animation: _away,
            builder: (context, child) {
              final t = Curves.easeIn.transform(_away.value);
              return Opacity(
                opacity: 1 - t,
                child: Transform(
                  alignment: Alignment.center,
                  transform:
                      Matrix4.translationValues(-s * 0.6 * t, -s * 0.8 * t, 0)
                        ..multiply(Matrix4.rotationZ(-25 * math.pi / 180 * t)),
                  child: child,
                ),
              );
            },
            child: SizedBox.square(
              dimension: s,
              child: _buildNote(theme, color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNote(PaperThemeData theme, Color color) {
    final fold = PeelGeometry(size: widget.size, tip: _tip);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _NotePainter(
              polygon: fold.visible,
              color: color,
              dark: theme.isDark,
            ),
          ),
        ),
        Positioned.fill(
          child: ClipPath(
            clipper: _PolygonClipper(fold.visible),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle.merge(
                style: theme.text(size: 15, weight: FontWeight.w600),
                child: widget.child,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _FlapPainter(
                flap: fold.flap,
                foldA: fold.foldStart,
                foldB: fold.foldEnd,
                tip: _tip,
                color: color,
                dark: theme.isDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Where a square note folds when its bottom-right corner is lifted to [tip].
///
/// The fold line is the perpendicular bisector of the corner and the tip. The
/// part beyond it is reflected across the line to make the flap.
@visibleForTesting
class PeelGeometry {
  /// Works out the fold for a note of [size] whose corner sits at [tip].
  PeelGeometry({required this.size, required this.tip}) {
    final corner = Offset(size, size);
    final square = [
      Offset.zero,
      Offset(size, 0),
      Offset(size, size),
      Offset(0, size),
    ];
    final delta = corner - tip;
    if (delta.distance < 0.5) {
      visible = square;
      flap = const [];
      return;
    }
    final mid = (corner + tip) / 2;
    final normal = delta / delta.distance;
    double side(Offset point) {
      final d = point - mid;
      return d.dx * normal.dx + d.dy * normal.dy;
    }

    visible = _clip(square, side, keepNegative: true);
    final beyond = _clip(square, side, keepNegative: false);
    flap = [
      for (final point in beyond) point - normal * (2 * side(point)),
    ];
    final along = Offset(-normal.dy, normal.dx);
    foldStart = mid + along * size * 2;
    foldEnd = mid - along * size * 2;
  }

  /// The note's width and height.
  final double size;

  /// Where the lifted corner is.
  final Offset tip;

  /// The flat part of the note.
  late final List<Offset> visible;

  /// The folded-back corner, already reflected.
  late final List<Offset> flap;

  /// One end of a long segment along the fold line.
  Offset foldStart = Offset.zero;

  /// The other end.
  Offset foldEnd = Offset.zero;

  static List<Offset> _clip(
    List<Offset> polygon,
    double Function(Offset) side, {
    required bool keepNegative,
  }) {
    bool inside(Offset p) => keepNegative ? side(p) <= 0 : side(p) >= 0;
    final result = <Offset>[];
    for (var i = 0; i < polygon.length; i++) {
      final current = polygon[i];
      final next = polygon[(i + 1) % polygon.length];
      final currentIn = inside(current);
      final nextIn = inside(next);
      if (currentIn) result.add(current);
      if (currentIn != nextIn) {
        final a = side(current);
        final b = side(next);
        result.add(Offset.lerp(current, next, a / (a - b))!);
      }
    }
    return result;
  }
}

Path _polygonPath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) return path;
  path.moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

class _PolygonClipper extends CustomClipper<Path> {
  const _PolygonClipper(this.points);

  final List<Offset> points;

  @override
  Path getClip(Size size) => _polygonPath(points);

  @override
  bool shouldReclip(_PolygonClipper oldClipper) => true;
}

class _NotePainter extends CustomPainter {
  const _NotePainter({
    required this.polygon,
    required this.color,
    required this.dark,
  });

  final List<Offset> polygon;
  final Color color;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _polygonPath(polygon);
    canvas
      ..drawShadow(
        path,
        dark ? const Color(0xFF000000) : const Color(0xFF3A2A12),
        3,
        false,
      )
      ..drawPath(path, Paint()..color = color);
    // A slightly darker band at the top, where the glue is.
    canvas
      ..save()
      ..clipPath(path)
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, 22),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF000000).withValues(alpha: dark ? 0.12 : 0.05),
              const Color(0x00000000),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, 22)),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_NotePainter oldDelegate) => true;
}

class _FlapPainter extends CustomPainter {
  const _FlapPainter({
    required this.flap,
    required this.foldA,
    required this.foldB,
    required this.tip,
    required this.color,
    required this.dark,
  });

  final List<Offset> flap;
  final Offset foldA;
  final Offset foldB;
  final Offset tip;
  final Color color;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (flap.length < 3) return;
    final path = _polygonPath(flap);
    final back = Color.lerp(color, const Color(0xFF000000), 0.1)!;
    canvas.drawShadow(
      path.shift(const Offset(-1, -1)),
      const Color(0xFF000000),
      4,
      false,
    );
    // Shade from the tip (lightest) toward the fold (darkest).
    final foldPoint = _closestOnLine(tip, foldA, foldB);
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(tip, foldPoint, [
          back,
          Color.lerp(back, const Color(0xFF000000), dark ? 0.25 : 0.16)!,
        ]),
    );
  }

  static Offset _closestOnLine(Offset point, Offset a, Offset b) {
    final ab = b - a;
    final t = ((point - a).dx * ab.dx + (point - a).dy * ab.dy) /
        (ab.dx * ab.dx + ab.dy * ab.dy);
    return a + ab * t;
  }

  @override
  bool shouldRepaint(_FlapPainter oldDelegate) => true;
}
