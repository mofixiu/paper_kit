import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'haptics.dart';
import 'stamp.dart';
import 'theme.dart';

/// A paper ticket you confirm by tearing off its stub.
///
/// Drag the stub to the right: it resists, then tears along the perforation and
/// falls away, and the ticket is stamped "confirmed". Let go too early and it
/// springs back.
class PaperTearToConfirm extends StatefulWidget {
  /// A ticket reading [label].
  const PaperTearToConfirm({
    super.key,
    required this.label,
    this.stubLabel = 'tear',
    required this.onConfirmed,
    this.onReset,
    this.confirmedLabel = 'confirmed',
    this.height = 96,
  });

  /// The text on the ticket.
  final String label;

  /// The word on the stub, written sideways. It is shown in lowercase.
  final String stubLabel;

  /// Called once the stub has torn off and fallen.
  final VoidCallback onConfirmed;

  /// Called when [PaperTearToConfirmState.reset] puts the stub back.
  final VoidCallback? onReset;

  /// The word stamped on the ticket after tearing.
  final String confirmedLabel;

  /// The ticket's height.
  final double height;

  @override
  PaperTearToConfirmState createState() => PaperTearToConfirmState();
}

/// The state of a [PaperTearToConfirm]. Use a `GlobalKey` to call [reset] or [tear].
class PaperTearToConfirmState extends State<PaperTearToConfirm>
    with TickerProviderStateMixin {
  static const double _threshold = 64;

  double _drag = 0;
  bool _torn = false;

  late final AnimationController _spring;
  late final AnimationController _fall;
  late final AnimationController _stamp;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fall = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _stamp = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  /// Whether the stub has been torn off.
  bool get isTorn => _torn;

  @override
  void dispose() {
    _spring.dispose();
    _fall.dispose();
    _stamp.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_torn) return;
    _spring.stop();
    setState(() => _drag = math.max(0, _drag + details.delta.dx));
  }

  void _onDragEnd([DragEndDetails? details]) {
    if (_torn) return;
    if (_drag * 0.85 > _threshold) {
      _tearNow();
    } else {
      _springBack();
    }
  }

  void _springBack() {
    final from = _drag;
    final animation =
        CurvedAnimation(parent: _spring, curve: Curves.elasticOut);
    void listener() {
      if (!mounted) return;
      setState(() => _drag = math.max(0, from * (1 - animation.value)));
    }

    _spring
      ..stop()
      ..value = 0;
    animation.addListener(listener);
    _spring.forward().whenCompleteOrCancel(() {
      animation
        ..removeListener(listener)
        ..dispose();
    });
  }

  Future<void> _tearNow() async {
    setState(() => _torn = true);
    PaperHaptics.tear();
    await _fall.forward(from: 0);
    if (!mounted) return;
    _stamp.forward(from: 0);
    widget.onConfirmed();
  }

  /// Tears the stub off without a drag, as if it had been pulled.
  Future<void> tear() async {
    if (_torn) return;
    _spring.stop();
    setState(() => _drag = math.max(_drag, _threshold / 0.85 + 8));
    await _tearNow();
  }

  /// Puts the stub back and clears the stamp.
  void reset() {
    if (!_torn && _drag == 0) return;
    _stamp.reverse();
    _fall
        .animateBack(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    )
        .whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() => _torn = false);
      _springBack();
    });
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    return Semantics(
      button: true,
      label: _torn
          ? '${widget.label}, ${widget.confirmedLabel}'
          : '${widget.label}. Tear the stub to confirm',
      onTap: _torn ? null : tear,
      excludeSemantics: true,
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              tear();
              return null;
            },
          ),
        },
        child: SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
              final geometry = _TicketGeometry(Size(width, widget.height));
              return AnimatedBuilder(
                animation: Listenable.merge([_fall, _stamp]),
                builder: (context, _) => _buildTicket(theme, geometry),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTicket(PaperThemeData theme, _TicketGeometry geometry) {
    final p = theme.palette;
    final size = geometry.size;
    final separated = _torn || _drag > 0.5;
    final fall = Curves.easeIn.transform(_fall.value);
    final shift = _drag * 0.85;
    final turn = shift / 400 + (0.35 - shift / 400) * fall;
    final pivot = Offset(geometry.perforation, size.height);
    final stubTransform = Matrix4.translationValues(
      pivot.dx + shift,
      pivot.dy + 140 * fall,
      0,
    )
      ..multiply(Matrix4.rotationZ(turn))
      ..multiply(Matrix4.translationValues(-pivot.dx, -pivot.dy, 0));
    final labelStyle = theme.text(size: 16, weight: FontWeight.w700);
    final stubStyle = theme.text(
      size: 12,
      weight: FontWeight.w700,
      letterSpacing: 1.5,
      color: p.muted,
    );

    final mainContent = Padding(
      padding: const EdgeInsets.only(left: 20, right: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          widget.label,
          style: labelStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    final stubContent = Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: size.width - geometry.perforation,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotatedBox(
                quarterTurns: 1,
                child: Text(widget.stubLabel.toLowerCase(), style: stubStyle),
              ),
              const SizedBox(width: 6),
              CustomPaint(
                size: const Size(7, 12),
                painter: _ChevronPainter(p.muted),
              ),
            ],
          ),
        ),
      ),
    );

    final children = <Widget>[];
    if (!separated) {
      children.add(
        Positioned.fill(
          child: _Piece(
            path: geometry.whole,
            fill: p.sheet,
            border: p.rule,
            dark: p.isDark,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: geometry.perforation,
                  child: mainContent,
                ),
                Positioned.fill(child: stubContent),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PerforationPainter(
                      x: geometry.perforation,
                      color: p.faint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      children
        ..add(
          Positioned.fill(
            child: _Piece(
              path: geometry.main,
              fill: p.sheet,
              border: p.rule,
              dark: p.isDark,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: geometry.perforation,
                    child: mainContent,
                  ),
                ],
              ),
            ),
          ),
        )
        ..add(
          Positioned.fill(
            child: Opacity(
              opacity: 1 - fall,
              child: Transform(
                transform: stubTransform,
                child: _Piece(
                  path: geometry.stub,
                  fill: p.sheet,
                  border: p.rule,
                  dark: p.isDark,
                  child: stubContent,
                ),
              ),
            ),
          ),
        );
    }
    if (_stamp.value > 0) {
      final t = Curves.easeOut.transform(_stamp.value);
      children.add(
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: geometry.perforation,
          child: IgnorePointer(
            child: Align(
              alignment: const Alignment(0.55, 0),
              child: Transform.rotate(
                angle: -0.12,
                child: Transform.scale(
                  scale: 1.18 - 0.18 * t,
                  child: PaperStampImpression(
                    label: widget.confirmedLabel,
                    seed: widget.label.hashCode & 0xff,
                    fontSize: 12,
                    opacity: 0.9 * t,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    children.add(
      Positioned(
        left: geometry.perforation,
        right: 0,
        top: 0,
        bottom: 0,
        child: MouseRegion(
          cursor: _torn ? SystemMouseCursors.basic : SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: _torn ? null : _onDragUpdate,
            onHorizontalDragEnd: _torn ? null : _onDragEnd,
            onHorizontalDragCancel: _torn ? null : _onDragEnd,
          ),
        ),
      ),
    );
    return Stack(clipBehavior: Clip.none, children: children);
  }
}

/// The ticket outline, its perforation and the two pieces it tears into.
class _TicketGeometry {
  _TicketGeometry(this.size) : perforation = size.width * 0.72;

  final Size size;
  final double perforation;

  static const double notch = 9;
  static const double amplitude = 3;
  static const double period = 6;

  late final Path whole = Path.combine(
    PathOperation.difference,
    Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      ),
    Path()
      ..addOval(Rect.fromCircle(center: Offset(perforation, 0), radius: notch))
      ..addOval(
        Rect.fromCircle(
            center: Offset(perforation, size.height), radius: notch),
      ),
  );

  /// The torn edge, from top to bottom.
  List<Offset> get _zigzag {
    final points = <Offset>[];
    var i = 0;
    for (var y = 0.0; y <= size.height; y += period / 2, i++) {
      points.add(Offset(perforation + (i.isEven ? -amplitude : amplitude), y));
    }
    points.add(Offset(perforation, size.height));
    return points;
  }

  late final Path main = Path.combine(
    PathOperation.intersect,
    whole,
    _polygon([
      const Offset(-1, -1),
      Offset(perforation, -1),
      ..._zigzag,
      Offset(perforation, size.height + 1),
      Offset(-1, size.height + 1),
    ]),
  );

  late final Path stub = Path.combine(
    PathOperation.intersect,
    whole,
    _polygon([
      Offset(perforation, -1),
      Offset(size.width + 1, -1),
      Offset(size.width + 1, size.height + 1),
      Offset(perforation, size.height + 1),
      ..._zigzag.reversed,
    ]),
  );

  static Path _polygon(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }
}

/// A ticket piece: shadow, paper, a hairline border and its content clipped inside.
class _Piece extends StatelessWidget {
  const _Piece({
    required this.path,
    required this.fill,
    required this.border,
    required this.dark,
    required this.child,
  });

  final Path path;
  final Color fill;
  final Color border;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PiecePainter(path: path, fill: fill, dark: dark),
      foregroundPainter: _PieceBorderPainter(path: path, color: border),
      child: ClipPath(clipper: _PathClipper(path), child: child),
    );
  }
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper oldClipper) => oldClipper.path != path;
}

class _PiecePainter extends CustomPainter {
  const _PiecePainter({
    required this.path,
    required this.fill,
    required this.dark,
  });

  final Path path;
  final Color fill;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawShadow(
        path,
        dark ? const Color(0xFF000000) : const Color(0xFF281A0E),
        3,
        false,
      )
      ..drawPath(path, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_PiecePainter oldDelegate) =>
      oldDelegate.path != path ||
      oldDelegate.fill != fill ||
      oldDelegate.dark != dark;
}

class _PieceBorderPainter extends CustomPainter {
  const _PieceBorderPainter({required this.path, required this.color});

  final Path path;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_PieceBorderPainter oldDelegate) =>
      oldDelegate.path != path || oldDelegate.color != color;
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({required this.x, required this.color});

  final double x;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (var y = _TicketGeometry.notch + 4;
        y < size.height - _TicketGeometry.notch - 4;
        y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 4), paint);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter oldDelegate) =>
      oldDelegate.x != x || oldDelegate.color != color;
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(1, 1)
        ..lineTo(size.width - 1, size.height / 2)
        ..lineTo(1, size.height - 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
}
