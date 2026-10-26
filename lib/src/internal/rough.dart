import 'dart:math' as math;
import 'dart:ui';

/// Slightly imperfect shapes, as if drawn by hand. Each takes a seed so the same
/// shape comes out on every frame.
abstract final class Rough {
  /// A rectangle drawn in one stroke: wobbly corners, sides that bow a little and
  /// an end that runs past the start by [overshoot].
  static Path rect(
    Rect rect, {
    required int seed,
    double jitter = 1.0,
    double bow = 0.7,
    double overshoot = 0,
  }) {
    final random = math.Random(seed);
    double wobble(double amount) => (random.nextDouble() * 2 - 1) * amount;
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ].map((c) => c.translate(wobble(jitter), wobble(jitter))).toList();

    final path = Path()..moveTo(corners[0].dx, corners[0].dy);
    for (var i = 1; i <= 4; i++) {
      final from = corners[i - 1];
      final to = corners[i % 4];
      final mid = Offset.lerp(from, to, 0.5)!;
      final direction = to - from;
      final normal = Offset(-direction.dy, direction.dx) / direction.distance;
      final control = mid + normal * wobble(bow);
      path.quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
    }
    if (overshoot > 0) {
      final direction = corners[1] - corners[0];
      final end = corners[0] + direction / direction.distance * overshoot;
      path.lineTo(end.dx, end.dy);
    }
    return path;
  }

  /// A straight line from [from] to [to] with a gentle sine wobble.
  static Path wavyLine(
    Offset from,
    Offset to, {
    double amplitude = 1.5,
    double wavelength = 8,
    double phase = 0,
  }) {
    final direction = to - from;
    final length = direction.distance;
    final path = Path()..moveTo(from.dx, from.dy);
    if (length == 0) return path;
    final unit = direction / length;
    final normal = Offset(-unit.dy, unit.dx);
    for (var s = 1.0; s <= length; s += 1) {
      final wave = math.sin(2 * math.pi * s / wavelength + phase) * amplitude;
      final point = from + unit * s + normal * wave;
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  /// The part of [path] from 0 to [t] of its length, for drawing a stroke in.
  static Path trim(Path path, double t) {
    final result = Path();
    if (t <= 0) return result;
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * t.clamp(0.0, 1.0);
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final length = math.min(remaining, metric.length);
      result.addPath(metric.extractPath(0, length), Offset.zero);
      remaining -= length;
    }
    return result;
  }

  /// A polygon through [points] with every corner rounded by up to [radius].
  static Path roundedPolygon(List<Offset> points, double radius) {
    final path = Path();
    final n = points.length;
    for (var i = 0; i < n; i++) {
      final previous = points[(i - 1 + n) % n];
      final corner = points[i];
      final next = points[(i + 1) % n];
      final toPrevious = previous - corner;
      final toNext = next - corner;
      final r = math.min(
        radius,
        math.min(toPrevious.distance, toNext.distance) / 2,
      );
      final start = toPrevious.distance == 0
          ? corner
          : corner + toPrevious / toPrevious.distance * r;
      final end =
          toNext.distance == 0 ? corner : corner + toNext / toNext.distance * r;
      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(corner.dx, corner.dy, end.dx, end.dy);
    }
    return path..close();
  }
}
