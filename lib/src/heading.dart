import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A lowercase bold heading with a short bar underneath, like a section title in a
/// notebook.
class PaperHeading extends StatelessWidget {
  /// Shows [text] in lowercase.
  const PaperHeading(
    this.text, {
    super.key,
    this.size = 28,
    this.color,
    this.barColor,
  });

  /// The heading. It is shown in lowercase.
  final String text;

  /// The font size. The bar keeps its size.
  final double size;

  /// The text colour. Defaults to the palette's ink.
  final Color? color;

  /// The bar colour. Defaults to the palette's primary.
  final Color? barColor;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    return Semantics(
      header: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.toLowerCase(),
            style: theme.text(
              size: size,
              weight: FontWeight.w700,
              color: color,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 40,
            height: 3,
            child: ColoredBox(color: barColor ?? theme.palette.primary),
          ),
        ],
      ),
    );
  }
}
