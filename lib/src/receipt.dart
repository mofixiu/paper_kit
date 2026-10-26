import 'dart:async';
import 'package:flutter/material.dart';

import 'theme.dart';

/// One line of a [PaperReceipt]: a label, dotted leaders and a value.
@immutable
class PaperReceiptLine {
  /// A line reading "[label] ..... [value]".
  const PaperReceiptLine(this.label, this.value);

  /// The left-hand text.
  final String label;

  /// The right-hand text, usually an amount.
  final String value;
}

/// A till receipt with a torn, zigzag bottom edge.
///
/// [PaperReceipt.show] prints one out of a slot at the top of the screen, holds
/// it for a moment, then tears it off: a toast that feels like paper.
class PaperReceipt extends StatelessWidget {
  /// A receipt headed [title].
  const PaperReceipt({
    super.key,
    required this.title,
    required this.lines,
    this.footer,
    this.width = 200,
  });

  /// The heading, shown in lowercase.
  final String title;

  /// The body.
  final List<PaperReceiptLine> lines;

  /// Small print under a dashed rule.
  final String? footer;

  /// The paper's width.
  final double width;

  /// Prints a receipt from a slot at the top of the screen and tears it off after
  /// [hold]. Tapping it tears it off early. Completes once it's gone.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<PaperReceiptLine> lines,
    String? footer,
    Duration hold = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final theme = PaperTheme.of(context);
    final completer = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => PaperTheme(
        data: theme,
        child: _ReceiptPrinter(
          hold: hold,
          receipt: PaperReceipt(title: title, lines: lines, footer: footer),
          onGone: () {
            entry
              ..remove()
              ..dispose();
            completer.complete();
          },
        ),
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    const figures = [FontFeature.tabularFigures()];
    final body = theme.text(size: 12, fontFeatures: figures);
    return Semantics(
      container: true,
      liveRegion: true,
      child: PhysicalShape(
        clipper: const _ZigzagBottom(),
        color: p.sheet,
        elevation: 4,
        shadowColor:
            p.isDark ? const Color(0xFF000000) : const Color(0x99281A0E),
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title.toLowerCase(),
                  textAlign: TextAlign.center,
                  style: theme.text(
                    size: 13,
                    weight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                _DashedRule(color: p.faint),
                const SizedBox(height: 6),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(line.label, style: body),
                        Expanded(
                          child: CustomPaint(
                            size: const Size.fromHeight(14),
                            painter: _LeaderPainter(p.faint),
                          ),
                        ),
                        Text(
                          line.value,
                          style: theme.text(
                            size: 12,
                            weight: FontWeight.w600,
                            fontFeatures: figures,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (footer != null) ...[
                  const SizedBox(height: 8),
                  _DashedRule(color: p.faint),
                  const SizedBox(height: 6),
                  Text(
                    footer!,
                    textAlign: TextAlign.center,
                    style: theme.text(size: 11, color: p.muted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptPrinter extends StatefulWidget {
  const _ReceiptPrinter({
    required this.receipt,
    required this.hold,
    required this.onGone,
  });

  final PaperReceipt receipt;
  final Duration hold;
  final VoidCallback onGone;

  @override
  State<_ReceiptPrinter> createState() => _ReceiptPrinterState();
}

class _ReceiptPrinterState extends State<_ReceiptPrinter>
    with TickerProviderStateMixin {
  late final AnimationController _feed;
  late final AnimationController _tear;
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _feed = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _tear = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feed.forward().whenComplete(() {
      if (mounted) _timer = Timer(widget.hold, _tearOff);
    });
  }

  void _tearOff() {
    if (_leaving) return;
    _leaving = true;
    _timer?.cancel();
    _tear.forward().whenComplete(widget.onGone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feed.dispose();
    _tear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PaperTheme.of(context).palette;
    final top = MediaQuery.paddingOf(context).top + 12;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: Listenable.merge([_feed, _tear]),
        builder: (context, _) {
          final fed = const _PrinterSteps(6).transform(_feed.value);
          final gone = Curves.easeIn.transform(_tear.value);
          return Opacity(
            opacity: 1 - gone,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 220,
                  height: 6,
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: fed,
                    child: Transform.translate(
                      offset: Offset(0, 24 * gone),
                      child: Transform.rotate(
                        angle: -0.0524 * gone,
                        alignment: Alignment.topCenter,
                        child: FractionalTranslation(
                          translation: Offset(0, fed - 1),
                          child: GestureDetector(
                            onTap: _tearOff,
                            child: widget.receipt,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Six jerky feeds, like a thermal printer.
class _PrinterSteps extends Curve {
  const _PrinterSteps(this.steps);

  final int steps;

  @override
  double transformInternal(double t) {
    final position = t * steps;
    final step = position.floor();
    if (step >= steps) return 1;
    final within = ((position - step) / 0.45).clamp(0.0, 1.0);
    return (step + Curves.easeOut.transform(within)) / steps;
  }
}

class _ZigzagBottom extends CustomClipper<Path> {
  const _ZigzagBottom();

  @override
  Path getClip(Size size) {
    const tooth = 8.0;
    const depth = 4.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - depth);
    final count = (size.width / tooth).ceil();
    final step = size.width / count;
    for (var i = count; i > 0; i--) {
      final x = i * step;
      path
        ..lineTo(x - step / 2, size.height)
        ..lineTo(x - step, size.height - depth);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_ZigzagBottom oldClipper) => false;
}

class _DashedRule extends StatelessWidget {
  const _DashedRule({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.fromHeight(1),
      painter: _DashPainter(color),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 3, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}

class _LeaderPainter extends CustomPainter {
  const _LeaderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final y = size.height - 3;
    for (var x = 4.0; x < size.width - 3; x += 4) {
      canvas.drawCircle(Offset(x, y), 0.65, paint);
    }
  }

  @override
  bool shouldRepaint(_LeaderPainter oldDelegate) => oldDelegate.color != color;
}
