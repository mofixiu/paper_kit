import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'internal/pressable.dart';
import 'internal/rough.dart';
import 'motion.dart';
import 'theme.dart';

enum _Phase { idle, folding, flying, sent }

/// A send button that folds itself into a paper plane and flies off.
///
/// When the plane is gone, [onSent] is called and the button comes back saying
/// "✓ sent" for a moment.
class PaperPlaneButton extends StatefulWidget {
  /// A button reading [label].
  const PaperPlaneButton({
    super.key,
    this.label = 'send',
    this.sentLabel = 'sent',
    required this.onSent,
  });

  /// The button's word. It is shown in lowercase.
  final String label;

  /// Shown with a tick after the plane has gone.
  final String sentLabel;

  /// Called once the plane has flown off.
  final VoidCallback onSent;

  @override
  State<PaperPlaneButton> createState() => _PaperPlaneButtonState();
}

class _PaperPlaneButtonState extends State<PaperPlaneButton>
    with TickerProviderStateMixin {
  late final AnimationController _fold;
  late final AnimationController _fly;
  late final AnimationController _back;

  @override
  void initState() {
    super.initState();
    _fold = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fly = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _back = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  _Phase _phase = _Phase.idle;
  Timer? _timer;

  Future<void> _send() async {
    if (_phase != _Phase.idle) return;
    setState(() => _phase = _Phase.folding);
    await _fold.forward(from: 0);
    if (!mounted) return;
    setState(() => _phase = _Phase.flying);
    await _fly.forward(from: 0);
    if (!mounted) return;
    widget.onSent();
    setState(() => _phase = _Phase.sent);
    _back.forward(from: 0);
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _fold.value = 0;
      _fly.value = 0;
      setState(() => _phase = _Phase.idle);
      _back.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fold.dispose();
    _fly.dispose();
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    final style = theme.text(
      size: 14,
      weight: FontWeight.w700,
      letterSpacing: 0.5,
      color: p.onPrimary,
    );
    final label = widget.label.toLowerCase();
    final sent = widget.sentLabel.toLowerCase();
    return Pressable(
      semanticLabel: _phase == _Phase.sent ? sent : label,
      focusRadius: 12,
      onTap: _phase == _Phase.idle ? _send : null,
      builder: (context, state) => AnimatedBuilder(
        animation: Listenable.merge([_fold, _fly, _back]),
        builder: (context, _) {
          final back = PaperMotion.fadeUp.transform(_back.value);
          final returning = _phase == _Phase.sent ||
              (_phase == _Phase.idle && _back.isAnimating);
          final fold = PaperMotion.inOut.transform(_fold.value);
          final labelOpacity = _phase == _Phase.idle
              ? (returning ? back : 1.0)
              : _phase == _Phase.folding
                  ? (1 - _fold.value * 350 / 120).clamp(0.0, 1.0)
                  : 0.0;
          return Transform.translate(
            offset: Offset(0, state.pressed ? 1 : 0),
            child: CustomPaint(
              painter: _PlanePainter(
                color: p.primary,
                fold: _phase == _Phase.folding || _phase == _Phase.flying
                    ? fold
                    : 0,
                fly: _phase == _Phase.flying ? _fly.value : 0,
                visible: _phase == _Phase.folding || _phase == _Phase.flying
                    ? 1
                    : (returning ? back : 1),
                foldLine: p.onPrimary.withValues(alpha: 0.45),
                hovered: state.hovered,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: _phase == _Phase.sent ? 0 : labelOpacity,
                      child: Text(label, style: style),
                    ),
                    Opacity(
                      opacity: _phase == _Phase.sent ? back : 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomPaint(
                            size: const Size(12, 10),
                            painter: _TickPainter(p.onPrimary),
                          ),
                          const SizedBox(width: 6),
                          Text(sent, style: style),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanePainter extends CustomPainter {
  const _PlanePainter({
    required this.color,
    required this.fold,
    required this.fly,
    required this.visible,
    required this.foldLine,
    required this.hovered,
  });

  final Color color;
  final double fold;
  final double fly;
  final double visible;
  final Color foldLine;
  final bool hovered;

  static const _nose = Offset(30, -6);
  static const _notch = Offset(-12, 0);
  static const _plane = [
    _nose,
    Offset(-2, 6),
    Offset(-20, 15),
    _notch,
    Offset(-28, -16),
    Offset(0, -11.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (visible <= 0) return;
    final w = size.width / 2;
    final h = size.height / 2;
    final button = [
      Offset(w, -h),
      Offset(w, h),
      Offset(0, h),
      Offset(-w, h),
      Offset(-w, -h),
      Offset(0, -h),
    ];
    final points = [
      for (var i = 0; i < button.length; i++)
        Offset.lerp(button[i], _plane[i], fold)!,
    ];

    const p1 = Offset(70, 10);
    const p2 = Offset(180, -120);
    final u = 1 - fly;
    final position = p1 * (2 * u * fly) + p2 * (fly * fly);
    final eased = Curves.easeIn.transform(fly);
    final alpha = visible * (1 - eased * eased);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    if (fly > 0) {
      final trail = Paint()..color = color.withValues(alpha: 0.35 * (1 - fly));
      for (var i = 0; i < 14; i++) {
        final s = fly * i / 14;
        final v = 1 - s;
        final point = p1 * (2 * v * s) + p2 * (s * s);
        canvas.drawCircle(point + const Offset(-14, 6), 1.2, trail);
      }
    }

    canvas
      ..translate(position.dx, position.dy)
      ..rotate(-20 * math.pi / 180 * fly)
      ..scale(1 - 0.5 * fly);

    final paint = Paint()
      ..color = color.withValues(
          alpha: color.a * alpha * (hovered && fold == 0 ? 0.92 : 1));
    final shape = Rough.roundedPolygon(points, 10 - 8.5 * fold);
    canvas.drawPath(shape, paint);
    if (fold > 0) {
      canvas.drawLine(
        Offset.lerp(button[0], _nose, fold)!,
        Offset.lerp(button[3], _notch, fold)!,
        Paint()
          ..color = foldLine.withValues(alpha: foldLine.a * fold * alpha)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlanePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.fold != fold ||
      oldDelegate.fly != fly ||
      oldDelegate.visible != visible ||
      oldDelegate.foldLine != foldLine ||
      oldDelegate.hovered != hovered;
}

class _TickPainter extends CustomPainter {
  const _TickPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(1, size.height * 0.55)
        ..lineTo(size.width * 0.38, size.height - 1)
        ..lineTo(size.width - 1, 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) => oldDelegate.color != color;
}
