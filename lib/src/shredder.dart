import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'theme.dart';

/// A strip-cut shredder for deleting things. [PaperShredderState.shred] feeds
/// [child] down into a slot; it comes out underneath as strips that curl apart
/// and fall away.
///
/// ```dart
/// final _shredder = GlobalKey<PaperShredderState>();
/// PaperShredder(key: _shredder, child: draft, onShredded: deleteDraft);
/// _shredder.currentState!.shred();
/// ```
class PaperShredder extends StatefulWidget {
  /// A shredder holding [child].
  const PaperShredder({
    super.key,
    required this.child,
    this.strips = 14,
    this.onShredded,
  });

  /// What gets shredded.
  final Widget child;

  /// How many strips it is cut into.
  final int strips;

  /// Called once the last strip has fallen.
  final VoidCallback? onShredded;

  @override
  State<PaperShredder> createState() => PaperShredderState();
}

/// The state of a [PaperShredder].
class PaperShredderState extends State<PaperShredder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  final _childKey = GlobalKey();
  Size? _size;

  /// Whether the child has been shredded (or is being).
  bool get isShredded => _controller.value > 0;

  /// Feeds the child into the slot.
  Future<void> shred() async {
    final box = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    setState(() => _size = box.size);
    await _controller.forward(from: 0);
    if (mounted) widget.onShredded?.call();
  }

  /// Brings a fresh copy back.
  void reset() {
    _controller.value = 0;
    setState(() => _size = null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PaperTheme.of(context).palette;
    final whole = KeyedSubtree(key: _childKey, child: widget.child);
    final size = _size;
    if (size == null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(padding: const EdgeInsets.only(bottom: 10), child: whole),
          Positioned(
            left: -8,
            right: -8,
            bottom: 0,
            child: _Slot(color: p.primary),
          ),
        ],
      );
    }
    return SizedBox(
      width: size.width,
      height: size.height + 10,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final feed =
              size.height * PaperMotion.inOut.transform((t / 0.62).clamp(0, 1));
          final slotY = size.height;
          final count = math.max(2, widget.strips);
          final stripWidth = size.width / count;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: feed,
                width: size.width,
                height: size.height,
                child: ClipRect(
                  clipper: _RectClipper(
                      Rect.fromLTRB(0, 0, size.width, size.height - feed)),
                  child: widget.child,
                ),
              ),
              for (var i = 0; i < count; i++)
                _strip(i, count, stripWidth, size, feed, slotY, t),
              Positioned(
                left: -8,
                right: -8,
                top: slotY,
                child: _Slot(color: p.primary),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _strip(int i, int count, double stripWidth, Size size, double feed,
      double slotY, double t) {
    final start = 0.6 + 0.25 * ((i * 7) % count) / count;
    final fall = ((t - start) / 0.25).clamp(0.0, 1.0);
    final curl = (i.isEven ? 1 : -1) * (0.03 + 0.02 * math.sin(i * 1.7));
    final out = feed / size.height;
    final left = i * stripWidth;
    return Positioned(
      left: 0,
      top: feed + fall * fall * size.height * 0.8,
      width: size.width,
      height: size.height,
      child: Opacity(
        opacity: 1 - fall,
        child: Transform(
          alignment: Alignment((left + stripWidth / 2) / size.width * 2 - 1,
              ((slotY - feed) / size.height) * 2 - 1),
          transform: Matrix4.rotationZ(curl * out + curl * 3 * fall),
          child: ClipRect(
            clipper: _RectClipper(Rect.fromLTRB(
              left + 0.5,
              size.height - feed,
              left + stripWidth - 0.5,
              size.height,
            )),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _RectClipper extends CustomClipper<Rect> {
  _RectClipper(this.rect);

  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(_RectClipper old) => old.rect != rect;
}

class _Slot extends StatelessWidget {
  const _Slot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: CustomPaint(painter: _SlotPainter(color)),
    );
  }
}

class _SlotPainter extends CustomPainter {
  _SlotPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bar =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3));
    canvas.drawShadow(Path()..addRRect(bar), const Color(0xFF000000), 3, false);
    canvas.drawRRect(bar, Paint()..color = color);
    final teeth = Paint()
      ..color = Color.lerp(color, const Color(0xFFFFFFFF), 0.25)!
      ..strokeWidth = 1;
    for (var x = 6.0; x < size.width - 4; x += 5) {
      canvas.drawLine(
          Offset(x, size.height * 0.35), Offset(x, size.height * 0.7), teeth);
    }
  }

  @override
  bool shouldRepaint(_SlotPainter old) => old.color != color;
}
