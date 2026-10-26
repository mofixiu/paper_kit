import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'motion.dart';
import 'theme.dart';

/// Applies [theme] to [child] and, when the palette changes, lets the new one
/// spread over the old like a drop of ink soaking into paper.
///
/// Put it at the root of the app (for example in `MaterialApp.builder`). It also
/// provides [PaperTheme], a matching Material [Theme] and a default text style.
class PaperInkReveal extends StatefulWidget {
  /// Themes [child] with [theme].
  const PaperInkReveal({
    super.key,
    required this.theme,
    required this.child,
    this.origin,
    this.duration = const Duration(milliseconds: 700),
  });

  /// The theme to show. Changing its palette starts the ink.
  final PaperThemeData theme;

  /// The app.
  final Widget child;

  /// Where the ink lands, in this widget's coordinates. Defaults to the centre.
  final Offset? origin;

  /// How long the ink takes to cover everything.
  final Duration duration;

  @override
  State<PaperInkReveal> createState() => _PaperInkRevealState();
}

class _PaperInkRevealState extends State<PaperInkReveal>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late PaperThemeData _shown = widget.theme;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _dropSnapshot();
      });
  }

  ui.Image? _snapshot;
  int _seed = 0;
  bool _waiting = false;

  @override
  void didUpdateWidget(PaperInkReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (widget.theme.palette == _shown.palette) {
      _shown = widget.theme;
      return;
    }
    if (_waiting) return;
    // Paint one more frame in the old colours, photograph it, then switch underneath.
    _waiting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startInk());
  }

  void _startInk() {
    _waiting = false;
    if (!mounted) return;
    final boundary =
        _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    ui.Image? snapshot;
    if (boundary != null && boundary.hasSize) {
      try {
        snapshot = boundary.toImageSync(
          pixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
        );
      } catch (_) {
        // Not ready to be photographed: switch without the ink.
        snapshot = null;
      }
    }
    setState(() {
      _snapshot?.dispose();
      _snapshot = snapshot;
      _shown = widget.theme;
      _seed++;
    });
    if (snapshot != null) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  void _dropSnapshot() {
    if (!mounted) return;
    setState(() {
      _snapshot?.dispose();
      _snapshot = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _shown;
    Widget themed = PaperTheme(
      data: theme,
      child: Theme(
        data: theme.toMaterialTheme(),
        child: DefaultTextStyle.merge(
          style: theme.text(),
          child: widget.child,
        ),
      ),
    );
    themed = RepaintBoundary(key: _boundary, child: themed);
    final snapshot = _snapshot;
    if (snapshot == null) return themed;
    return AnimatedBuilder(
      animation: _controller,
      child: themed,
      builder: (context, child) => CustomPaint(
        foregroundPainter: _OldPagePainter(
          image: snapshot,
          progress: PaperMotion.ink.transform(_controller.value),
          origin: widget.origin,
          seed: _seed,
        ),
        child: child,
      ),
    );
  }
}

/// Paints the photograph of the old theme everywhere the ink hasn't reached yet.
class _OldPagePainter extends CustomPainter {
  const _OldPagePainter({
    required this.image,
    required this.progress,
    required this.origin,
    required this.seed,
  });

  final ui.Image image;
  final double progress;
  final Offset? origin;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final centre = origin ?? bounds.center;
    final reach = [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ].map((corner) => (corner - centre).distance).reduce(math.max);
    final blot = inkBlot(centre, reach * 1.25 * progress, seed);
    final uncovered = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds)
      ..addPath(blot, Offset.zero);
    canvas
      ..save()
      ..clipPath(uncovered)
      ..drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        bounds,
        Paint()..filterQuality = FilterQuality.medium,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_OldPagePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.progress != progress ||
      oldDelegate.origin != origin;
}

/// A wobbly circle: a circle whose radius rises and falls with a few slow waves.
Path inkBlot(Offset centre, double radius, int seed) {
  final path = Path();
  if (radius <= 0) return path;
  final random = math.Random(seed * 31 + 7);
  final phases = List.generate(4, (_) => random.nextDouble() * math.pi * 2);
  const count = 120;
  final points = <Offset>[];
  for (var i = 0; i < count; i++) {
    final angle = i / count * math.pi * 2;
    final wobble = 0.07 * math.sin(3 * angle + phases[0]) +
        0.045 * math.sin(5 * angle + phases[1]) +
        0.025 * math.sin(9 * angle + phases[2]) +
        0.012 * math.sin(17 * angle + phases[3]) +
        (random.nextDouble() - 0.5) * 0.012;
    final r = radius * (1 + wobble);
    points.add(centre + Offset(math.cos(angle), math.sin(angle)) * r);
  }
  // A smooth closed curve through the midpoints.
  final first = Offset.lerp(points.last, points.first, 0.5)!;
  path.moveTo(first.dx, first.dy);
  for (var i = 0; i < count; i++) {
    final point = points[i];
    final next = points[(i + 1) % count];
    final mid = Offset.lerp(point, next, 0.5)!;
    path.quadraticBezierTo(point.dx, point.dy, mid.dx, mid.dy);
  }
  return path..close();
}
