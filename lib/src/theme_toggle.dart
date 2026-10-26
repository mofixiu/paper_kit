import 'package:flutter/widgets.dart';

import 'internal/pressable.dart';
import 'motion.dart';
import 'theme.dart';

/// A text switch between light and dark paper: a lowercase word naming the theme it
/// switches to, beside a half-inked dot that turns over on every switch.
class PaperThemeToggle extends StatefulWidget {
  /// Shows "dark" while [isDark] is false and "light" while it's true.
  const PaperThemeToggle({
    super.key,
    required this.isDark,
    required this.onChanged,
  });

  /// Whether the dark theme is on.
  final bool isDark;

  /// Called with the new value when tapped.
  final ValueChanged<bool> onChanged;

  @override
  State<PaperThemeToggle> createState() => _PaperThemeToggleState();
}

class _PaperThemeToggleState extends State<PaperThemeToggle> {
  late double _turns = widget.isDark ? 0.5 : 0;

  @override
  void didUpdateWidget(PaperThemeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) _turns += 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final target = widget.isDark ? 'light' : 'dark';
    return Pressable(
      semanticLabel: 'Switch to $target mode',
      onTap: () => widget.onChanged(!widget.isDark),
      builder: (context, state) {
        final color = state.hovered ? theme.palette.ink : theme.palette.muted;
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: color),
          duration: const Duration(milliseconds: 300),
          builder: (context, color, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _turns,
                    duration: const Duration(milliseconds: 400),
                    curve: PaperMotion.inOut,
                    child: CustomPaint(
                      size: const Size.square(12),
                      painter: _HalfInkedDot(color!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    target,
                    style: theme.text(
                      size: 14,
                      weight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HalfInkedDot extends CustomPainter {
  const _HalfInkedDot(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height))
      ..drawCircle(centre, radius, Paint()..color = color)
      ..restore()
      ..drawCircle(
        centre,
        radius - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
      );
  }

  @override
  bool shouldRepaint(_HalfInkedDot oldDelegate) => oldDelegate.color != color;
}
