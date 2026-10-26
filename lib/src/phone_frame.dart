import 'package:flutter/widgets.dart';

import 'demo.dart';
import 'theme.dart';

/// The colour of the status bar's time and icons in a [PaperPhoneFrame].
enum PaperStatusBarStyle {
  /// Dark glyphs, for light screens.
  dark,

  /// White glyphs, for dark screens.
  light,

  /// No status bar.
  hidden,
}

/// An iPhone drawn in code, for showing an app on a page: rounded body, bevelled
/// edge, side buttons, a Dynamic Island and a 9:41 status bar.
///
/// Give it a [demo] controller to add a [PaperFingertip] that can tap through the
/// app by itself. A real touch on the screen interrupts the demo.
class PaperPhoneFrame extends StatelessWidget {
  /// A phone showing [child] on its screen.
  const PaperPhoneFrame({
    super.key,
    required this.child,
    this.width = 300,
    this.island = true,
    this.statusBar = PaperStatusBarStyle.dark,
    this.demo,
  });

  /// The app on the screen. It gets a [MediaQuery] the size of the screen, with
  /// top padding for the status bar.
  final Widget child;

  /// The phone's width. Everything else scales with it.
  final double width;

  /// Whether to draw the Dynamic Island.
  final bool island;

  /// The status bar's colour, or [PaperStatusBarStyle.hidden].
  final PaperStatusBarStyle statusBar;

  /// Drives a fingertip over the screen.
  final PaperDemoController? demo;

  /// The screen's aspect ratio (width / height).
  static const double screenAspectRatio = 720 / 1565;

  @override
  Widget build(BuildContext context) {
    final w = width;
    final pad = w * 0.036;
    final screenWidth = w - pad * 2;
    final screenHeight = screenWidth / screenAspectRatio;
    final height = screenHeight + pad * 2;
    final radius = Radius.circular(w * 0.165);

    final media =
        (MediaQuery.maybeOf(context) ?? const MediaQueryData()).copyWith(
      size: Size(screenWidth, screenHeight),
      padding: EdgeInsets.only(
        top: screenHeight * 0.062,
        bottom: screenHeight * 0.025,
      ),
      viewPadding: EdgeInsets.only(
        top: screenHeight * 0.062,
        bottom: screenHeight * 0.025,
      ),
      viewInsets: EdgeInsets.zero,
    );

    // Scales down, never squashes, when there isn't room for the whole phone.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: w,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _button(left: -w * 0.01, top: height * 0.24, height: w * 0.2),
            _button(right: -w * 0.01, top: height * 0.27, height: w * 0.3),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF121214),
                  borderRadius: BorderRadius.all(radius),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99000000),
                      offset: Offset(0, 26),
                      blurRadius: 50,
                      spreadRadius: -22,
                    ),
                    BoxShadow(
                      color: Color(0x73000000),
                      offset: Offset(0, 10),
                      blurRadius: 20,
                      spreadRadius: -12,
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _BevelPainter(w)),
            ),
            Positioned(
              left: pad,
              top: pad,
              width: screenWidth,
              height: screenHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(w * 0.13),
                child: ColoredBox(
                  color: const Color(0xFF000000),
                  child: MediaQuery(
                    data: media,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerDown: (event) {
                              if (event.device != kPaperDemoPointerDevice) {
                                demo?.interrupt();
                              }
                            },
                            child: child,
                          ),
                        ),
                        if (statusBar != PaperStatusBarStyle.hidden)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: screenHeight * 0.062,
                            child: _StatusBar(
                              width: w,
                              screenWidth: screenWidth,
                              color: statusBar == PaperStatusBarStyle.light
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF111111),
                            ),
                          ),
                        if (island)
                          Positioned(
                            top: screenHeight * 0.0135,
                            left: screenWidth * 0.35,
                            width: screenWidth * 0.3,
                            height: screenHeight * 0.044,
                            child: const IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF000000),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(999)),
                                ),
                              ),
                            ),
                          ),
                        if (demo != null)
                          Positioned.fill(
                              child: PaperFingertip(controller: demo!)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({
    double? left,
    double? right,
    required double top,
    required double height,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      width: width * 0.012,
      height: height,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2E),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
    );
  }
}

class _BevelPainter extends CustomPainter {
  const _BevelPainter(this.width);

  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final band = width * 0.007;
    final radius = width * 0.165;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas
      ..drawRRect(
        outer.deflate(band * 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = band
          ..color = const Color(0xFF0B0B0C),
      )
      ..drawRRect(
        outer.deflate(band / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = band
          ..color = const Color(0xFF48484D),
      );
  }

  @override
  bool shouldRepaint(_BevelPainter oldDelegate) => oldDelegate.width != width;
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.width,
    required this.screenWidth,
    required this.color,
  });

  final double width;
  final double screenWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final iconHeight = width * 0.034;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.only(
            left: screenWidth * 0.12,
            right: screenWidth * 0.08,
            top: screenWidth * 0.008,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:41',
                style: theme.text(
                  size: width * 0.042,
                  weight: FontWeight.w600,
                  color: color,
                  height: 1,
                ),
              ),
              CustomPaint(
                size: Size(
                  (18 + 16 + 27) / 12 * iconHeight + width * 0.024,
                  iconHeight,
                ),
                painter: _StatusIconsPainter(color: color, gap: width * 0.012),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIconsPainter extends CustomPainter {
  const _StatusIconsPainter({required this.color, required this.gap});

  final Color color;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 12;
    final fill = Paint()..color = color;
    canvas.save();
    canvas.scale(s);

    // Signal bars.
    for (final (x, y, h) in const [
      (0.0, 8.0, 4.0),
      (5.0, 5.5, 6.5),
      (10.0, 3.0, 9.0),
      (15.0, 0.0, 12.0),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 3, h),
          const Radius.circular(1),
        ),
        fill,
      );
    }

    // Wi-Fi.
    canvas.translate(18 + gap / s, 0);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..color = color;
    const centre = Offset(8, 11.2);
    for (final r in const [10.0, 6.6]) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: r),
        -2.36,
        1.57,
        false,
        arc,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(8, 11.6)
        ..lineTo(5.4, 8.9)
        ..quadraticBezierTo(8, 6.6, 10.6, 8.9)
        ..close(),
      fill,
    );

    // Battery.
    canvas.translate(16 + gap / s, 0);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0.5, 0.5, 22, 11),
          const Radius.circular(3.2),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color.withValues(alpha: color.a * 0.4),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(2, 2, 19, 8),
          const Radius.circular(2),
        ),
        fill,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 4, 1.4, 4),
          const Radius.circular(0.7),
        ),
        Paint()..color = color.withValues(alpha: color.a * 0.45),
      );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StatusIconsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.gap != gap;
}
