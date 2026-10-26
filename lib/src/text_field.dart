import 'package:flutter/material.dart';

import 'internal/rough.dart';
import 'theme.dart';

/// A text field written on a ruled line. Focusing draws the line in ink from the
/// left; an error turns it into a wavy red-pen underline.
class PaperTextField extends StatefulWidget {
  /// A field with an optional [label] above it.
  const PaperTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
  });

  /// Shown above the line in small lowercase letters.
  final String? label;

  /// Shown on the line while it's empty.
  final String? hint;

  /// Controls the text. One is created if omitted.
  final TextEditingController? controller;

  /// Shown in red pen under the line, which turns wavy.
  final String? errorText;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the keyboard's action button is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Controls focus. One is created if omitted.
  final FocusNode? focusNode;

  /// The kind of keyboard to show.
  final TextInputType? keyboardType;

  /// The keyboard's action button.
  final TextInputAction? textInputAction;

  /// Whether to hide the text, for passwords.
  final bool obscureText;

  /// The most lines the field grows to.
  final int maxLines;

  @override
  State<PaperTextField> createState() => _PaperTextFieldState();
}

class _PaperTextFieldState extends State<PaperTextField>
    with SingleTickerProviderStateMixin {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  late final AnimationController _focus;

  @override
  void initState() {
    super.initState();
    _focus = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(PaperTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocus);
      _focusNode.addListener(_onFocus);
    }
  }

  void _onFocus() {
    if (_focusNode.hasFocus) {
      _focus.forward();
    } else {
      _focus.reverse();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _ownFocusNode?.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final palette = theme.palette;
    final error = widget.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!.toLowerCase(),
            style: theme.text(
              size: 12,
              weight: FontWeight.w700,
              letterSpacing: 0.5,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            style: theme.text(size: 16, color: palette.ink),
            cursorColor: palette.ink,
            cursorWidth: 1.5,
            decoration: InputDecoration.collapsed(
              hintText: widget.hint,
              hintStyle: theme.text(size: 16, color: palette.faint),
            ).copyWith(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _focus,
          builder: (context, _) => CustomPaint(
            size: const Size.fromHeight(8),
            painter: _UnderlinePainter(
              rule: palette.rule,
              ink: palette.ink,
              redPen: palette.redPen,
              focus: Curves.easeOutCubic.transform(_focus.value),
              error: error != null,
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error,
              style: theme.text(
                size: 12,
                fontStyle: FontStyle.italic,
                color: palette.redPen,
              ),
            ),
          ),
      ],
    );
  }
}

class _UnderlinePainter extends CustomPainter {
  const _UnderlinePainter({
    required this.rule,
    required this.ink,
    required this.redPen,
    required this.focus,
    required this.error,
  });

  final Color rule;
  final Color ink;
  final Color redPen;
  final double focus;
  final bool error;

  @override
  void paint(Canvas canvas, Size size) {
    if (error) {
      canvas.drawPath(
        Rough.wavyLine(
          const Offset(0, 3),
          Offset(size.width, 3),
          amplitude: 1.5,
          wavelength: 8,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = focus > 0 ? 1.8 : 1.4
          ..strokeCap = StrokeCap.round
          ..color = redPen,
      );
      return;
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 1, size.width, 1),
      Paint()..color = rule,
    );
    if (focus > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0.5, size.width * focus, 2),
        Paint()..color = ink,
      );
    }
  }

  @override
  bool shouldRepaint(_UnderlinePainter oldDelegate) =>
      oldDelegate.rule != rule ||
      oldDelegate.ink != ink ||
      oldDelegate.redPen != redPen ||
      oldDelegate.focus != focus ||
      oldDelegate.error != error;
}
