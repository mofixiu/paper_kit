import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'palette.dart';
import 'theme.dart';

/// The page: paper colour with a fine grain of fibres and specks.
///
/// The grain is drawn in code, so the package ships no images. Pass [texture] to
/// use a scanned paper instead.
class PaperBackground extends StatelessWidget {
  /// Paints paper behind [child].
  const PaperBackground({
    super.key,
    this.child,
    this.texture,
    this.grain = true,
    this.color,
  });

  /// What lies on the paper.
  final Widget? child;

  /// A tileable paper image to use instead of the drawn grain.
  final ImageProvider? texture;

  /// Whether to draw the grain. [PaperThemeData.grain] can also turn it off.
  final bool grain;

  /// The paper colour. Defaults to [PaperPalette.paper].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final paper = color ?? theme.palette.paper;
    if (texture != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: paper,
          image: DecorationImage(
            image: texture!,
            repeat: ImageRepeat.repeat,
            alignment: Alignment.topLeft,
          ),
        ),
        child: child,
      );
    }
    return CustomPaint(
      painter: _GrainPainter(
        paper: paper,
        palette: theme.palette,
        grain: grain && theme.grain,
        pixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
      ),
      child: child,
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({
    required this.paper,
    required this.palette,
    required this.grain,
    required this.pixelRatio,
  });

  final Color paper;
  final PaperPalette palette;
  final bool grain;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = paper);
    if (!grain || size.isEmpty) return;
    final tile = _GrainTile.of(palette.brightness, pixelRatio);
    final scale = 1 / tile.pixelRatio;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.ImageShader(
          tile.image,
          TileMode.repeated,
          TileMode.repeated,
          Float64List.fromList([
            scale, 0, 0, 0, //
            0, scale, 0, 0, //
            0, 0, 1, 0, //
            0, 0, 0, 1, //
          ]),
        ),
    );
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.paper != paper ||
      oldDelegate.palette != palette ||
      oldDelegate.grain != grain ||
      oldDelegate.pixelRatio != pixelRatio;
}

/// One square of grain, drawn once per brightness and pixel ratio and then tiled.
class _GrainTile {
  _GrainTile(this.image, this.pixelRatio);

  final ui.Image image;
  final double pixelRatio;

  static const double size = 240;
  static final Map<(Brightness, double), _GrainTile> _cache = {};

  static _GrainTile of(Brightness brightness, double pixelRatio) {
    final ratio = (pixelRatio * 2).round() / 2;
    return _cache.putIfAbsent(
      (brightness, ratio),
      () => _GrainTile(_draw(brightness, ratio), ratio),
    );
  }

  static ui.Image _draw(Brightness brightness, double ratio) {
    final dark = brightness == Brightness.dark;
    final random = math.Random(1729);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    final speckDark = dark ? black : const Color(0xFF3A2F22);
    final fibre = dark ? white : const Color(0xFF5A4A36);

    // Draws each mark at the nine positions around the tile so the edges wrap.
    void wrapped(void Function(Offset shift) draw) {
      for (var x = -1; x <= 1; x++) {
        for (var y = -1; y <= 1; y++) {
          draw(Offset(x * size, y * size));
        }
      }
    }

    double between(double a, double b) => a + random.nextDouble() * (b - a);

    // Soft mottling.
    for (var i = 0; i < 16; i++) {
      final centre = Offset(between(0, size), between(0, size));
      final radius = between(18, 64);
      final color = (random.nextBool() ? speckDark : white).withValues(
          alpha: dark ? between(0.008, 0.025) : between(0.012, 0.03));
      wrapped((shift) {
        canvas.drawCircle(
          centre + shift,
          radius,
          Paint()
            ..shader = ui.Gradient.radial(
              centre + shift,
              radius,
              [color, color.withValues(alpha: 0)],
            ),
        );
      });
    }

    // Fibres: short curved hairs.
    for (var i = 0; i < 110; i++) {
      final start = Offset(between(0, size), between(0, size));
      final angle = between(0, math.pi * 2);
      final length = between(3, 13);
      final end = start + Offset(math.cos(angle), math.sin(angle)) * length;
      final bend = Offset(between(-2.5, 2.5), between(-2.5, 2.5));
      final control = Offset.lerp(start, end, 0.5)! + bend;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = between(0.3, 0.65)
        ..color = fibre.withValues(
          alpha: dark ? between(0.025, 0.05) : between(0.035, 0.07),
        );
      wrapped((shift) {
        final s = start + shift;
        final c = control + shift;
        final e = end + shift;
        canvas.drawPath(
          Path()
            ..moveTo(s.dx, s.dy)
            ..quadraticBezierTo(c.dx, c.dy, e.dx, e.dy),
          paint,
        );
      });
    }

    // Specks.
    for (var i = 0; i < 1500; i++) {
      final centre = Offset(between(0, size), between(0, size));
      final radius = between(0.22, 0.85);
      final light = random.nextDouble() < (dark ? 0.55 : 0.3);
      final color = light
          ? white.withValues(
              alpha: dark ? between(0.02, 0.05) : between(0.08, 0.2))
          : speckDark.withValues(
              alpha: dark ? between(0.08, 0.18) : between(0.03, 0.08),
            );
      final paint = Paint()..color = color;
      wrapped((shift) => canvas.drawCircle(centre + shift, radius, paint));
    }

    final picture = recorder.endRecording();
    final pixels = (size * ratio).round();
    final image = picture.toImageSync(pixels, pixels);
    picture.dispose();
    return image;
  }
}
