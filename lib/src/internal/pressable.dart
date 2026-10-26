// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// What a [Pressable] is doing right now.
@immutable
class PressState {
  const PressState({
    this.hovered = false,
    this.pressed = false,
    this.focused = false,
  });

  final bool hovered;
  final bool pressed;
  final bool focused;
}

/// Taps, hover, keyboard activation and a focus ring for the kit's controls.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.builder,
    required this.onTap,
    this.semanticLabel,
    this.checked,
    this.selected,
    this.expanded,
    this.focusRadius = 6,
    this.focusInset = -3,
  });

  final Widget Function(BuildContext context, PressState state) builder;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool? checked;
  final bool? selected;
  final bool? expanded;
  final double focusRadius;
  final double focusInset;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  void _set({bool? hovered, bool? pressed, bool? focused}) {
    setState(() {
      _hovered = hovered ?? _hovered;
      _pressed = pressed ?? _pressed;
      _focused = focused ?? _focused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final theme = PaperTheme.of(context);
    final state =
        PressState(hovered: _hovered, pressed: _pressed, focused: _focused);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      checked: widget.checked,
      selected: widget.selected,
      expanded: widget.expanded,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (value) => _set(hovered: value),
        onShowFocusHighlight: (value) => _set(focused: value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(pressed: true) : null,
          onTapUp: enabled ? (_) => _set(pressed: false) : null,
          onTapCancel: enabled ? () => _set(pressed: false) : null,
          onTap: widget.onTap,
          child: CustomPaint(
            foregroundPainter: _focused
                ? _FocusRingPainter(
                    color: theme.palette.blueInk,
                    radius: widget.focusRadius,
                    inset: widget.focusInset,
                  )
                : null,
            child: ExcludeSemantics(
              excluding: widget.semanticLabel != null,
              child: widget.builder(context, state),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({
    required this.color,
    required this.radius,
    required this.inset,
  });

  final Color color;
  final double radius;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(inset);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.inset != inset;
}
