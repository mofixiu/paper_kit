import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'motion.dart';
import 'theme.dart';

/// A slip of paper held to a card with a wire paperclip. Tap to slide the slip
/// out from under the clip; tap again to clip it back on.
class PaperClip extends StatefulWidget {
  /// Clips [attachment] to the top-left corner of [child].
  const PaperClip({
    super.key,
    required this.child,
    required this.attachment,
    this.clipped = true,
    this.onChanged,
  });

  /// The card underneath.
  final Widget child;

  /// What's clipped to it: a photo, a receipt, a note.
  final Widget attachment;

  /// Whether it starts clipped on.
  final bool clipped;

  /// Called after each tap with whether it's clipped on now.
  final ValueChanged<bool>? onChanged;

  @override
  State<PaperClip> createState() => _PaperClipState();
}

class _PaperClipState extends State<PaperClip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _out = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: widget.clipped ? 0 : 1,
  );

  bool get _clipped =>
      _out.status == AnimationStatus.reverse ||
      _out.status == AnimationStatus.dismissed;

  void _toggle() {
    final clip = !_clipped;
    if (clip) {
      _out.reverse().whenComplete(PaperHaptics.clip);
    } else {
      _out.forward();
    }
    widget.onChanged?.call(clip);
  }

  @override
  void dispose() {
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PaperTheme.of(context).palette;
    final wire = p.isDark
        ? const [Color(0xFF8C8A86), Color(0xFFE6E3DD), Color(0xFF7A7873)]
        : const [Color(0xFF8A8883), Color(0xFFDCD9D2), Color(0xFF6A6863)];
    return Semantics(
      button: true,
      label: 'Paperclip',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(_toggle),
        child: AnimatedBuilder(
          animation: _out,
          builder: (context, _) {
            final t = PaperMotion.inOut.transform(_out.value);
            Widget clip(bool front) => Positioned(
                  left: 26,
                  top: -26,
                  child: Transform.rotate(
                    alignment: Alignment.bottomCenter,
                    angle: -0.22 * t,
                    child: Transform.translate(
                      offset: Offset(0, -6 * t),
                      child: CustomPaint(
                        size: const Size(22, 74),
                        painter: _ClipPainter(wire: wire, front: front),
                      ),
                    ),
                  ),
                );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                clip(false),
                widget.child,
                Positioned(
                  left: 14,
                  top: -12,
                  child: Transform.translate(
                    offset: Offset(-18 * t, 108 * t),
                    child: Transform.rotate(
                      angle: -0.045 - 0.1 * t,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x33000000),
                              blurRadius: 4 + 10 * t,
                              offset: Offset(0, 2 + 6 * t),
                            ),
                          ],
                        ),
                        child: widget.attachment,
                      ),
                    ),
                  ),
                ),
                clip(true),
              ],
            );
          },
        ),
      ),
    );
  }
}

// A Gem clip, bent from one wire: the inner loop lies in front of the paper and
// the outer loop behind it.
class _ClipPainter extends CustomPainter {
  _ClipPainter({required this.wire, required this.front});

  final List<Color> wire;
  final bool front;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path;
    if (front) {
      path = Path()
        ..moveTo(7, 58)
        ..lineTo(7, 14)
        ..arcToPoint(const Offset(15, 14), radius: const Radius.circular(4))
        ..lineTo(15, 64);
    } else {
      path = Path()
        ..moveTo(15, 64)
        ..arcToPoint(const Offset(1, 64), radius: const Radius.circular(7))
        ..lineTo(1, 8)
        ..arcToPoint(const Offset(21, 8), radius: const Radius.circular(10))
        ..lineTo(21, 52);
    }
    final metal = Paint()
      ..shader = LinearGradient(colors: wire).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      path.shift(const Offset(0.8, 1.2)),
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawPath(path, metal);
    canvas.drawPath(
      path.shift(const Offset(-0.5, -0.4)),
      Paint()
        ..color = const Color(0x80FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(_ClipPainter old) => old.front != front;
}
