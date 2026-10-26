import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Text typed out a key at a time, the way a typewriter strikes it: every letter
/// lands a hair off the line, a little crooked, some inked heavier than others,
/// and now and then struck twice.
class PaperTypewriter extends StatefulWidget {
  /// Types [text].
  const PaperTypewriter(
    this.text, {
    super.key,
    this.charDelay = const Duration(milliseconds: 55),
    this.style,
    this.seed = 7,
    this.autostart = true,
    this.onDone,
  });

  /// What gets typed. Newlines start a new line.
  final String text;

  /// The time between keys.
  final Duration charDelay;

  /// Overrides the typeface. Defaults to Courier at 16px in the palette's ink.
  final TextStyle? style;

  /// Seeds the wobble, so the same text always comes out the same way.
  final int seed;

  /// Starts typing as soon as it's shown. Otherwise call
  /// [PaperTypewriterState.type].
  final bool autostart;

  /// Called after the last key.
  final VoidCallback? onDone;

  @override
  State<PaperTypewriter> createState() => PaperTypewriterState();
}

/// The state of a [PaperTypewriter].
class PaperTypewriterState extends State<PaperTypewriter>
    with TickerProviderStateMixin {
  late AnimationController _keys;
  late final AnimationController _caret = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();
  late List<_Strike> _strikes;

  /// Types the text again from the start.
  Future<void> type() async {
    await _keys.forward(from: 0);
    if (mounted) widget.onDone?.call();
  }

  @override
  void initState() {
    super.initState();
    _setUp();
    if (widget.autostart) type();
  }

  void _setUp() {
    final characters = widget.text.characters.toList();
    _keys = AnimationController(
      vsync: this,
      duration: widget.charDelay * math.max(1, characters.length),
    );
    final random = math.Random(widget.seed);
    _strikes = [
      for (final character in characters)
        _Strike(
          character,
          dy: (random.nextDouble() - 0.5) * 1.4,
          angle: (random.nextDouble() - 0.5) * 0.05,
          ink: 0.72 + random.nextDouble() * 0.28,
          twice: random.nextDouble() < 0.07,
        ),
    ];
  }

  @override
  void didUpdateWidget(PaperTypewriter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.seed != widget.seed ||
        oldWidget.charDelay != widget.charDelay) {
      _keys.dispose();
      _setUp();
      if (widget.autostart) type();
    }
  }

  @override
  void dispose() {
    _keys.dispose();
    _caret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PaperTheme.of(context).palette;
    final style = TextStyle(
      fontFamily: 'Courier Prime',
      fontFamilyFallback: const ['Courier New', 'Courier', 'monospace'],
      fontSize: 16,
      height: 1.7,
      color: p.ink,
    ).merge(widget.style);

    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([_keys, _caret]),
          builder: (context, _) {
            final typed = (_keys.value * _strikes.length).floor();
            final done = _keys.isCompleted;
            return Text.rich(
              TextSpan(
                style: style,
                children: [
                  ..._words(_strikes.take(typed), style),
                  if (!done || _caret.value < 0.5)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Opacity(
                        opacity: done ? 1 : 0.85,
                        child:
                            Text('_', style: style.copyWith(color: p.redPen)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Iterable<InlineSpan> _words(Iterable<_Strike> strikes, TextStyle style) sync* {
  var word = <_Strike>[];
  Widget build(List<_Strike> keys) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [for (final key in keys) _Key(strike: key, style: style)],
      );
  for (final strike in strikes) {
    if (strike.character == ' ' || strike.character == '\n') {
      if (word.isNotEmpty) {
        yield WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: build(word),
        );
        word = [];
      }
      yield TextSpan(text: strike.character);
    } else {
      word.add(strike);
    }
  }
  if (word.isNotEmpty) {
    yield WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: build(word),
    );
  }
}

class _Strike {
  _Strike(
    this.character, {
    required this.dy,
    required this.angle,
    required this.ink,
    required this.twice,
  });

  final String character;
  final double dy;
  final double angle;
  final double ink;
  final bool twice;
}

class _Key extends StatelessWidget {
  const _Key({required this.strike, required this.style});

  final _Strike strike;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final color = style.color ?? const Color(0xFF211E19);
    final letter = Text(
      strike.character,
      style: style.copyWith(color: color.withValues(alpha: strike.ink)),
    );
    return Transform.translate(
      offset: Offset(0, strike.dy),
      child: Transform.rotate(
        angle: strike.angle,
        child: strike.twice
            ? Stack(
                children: [
                  Transform.translate(
                    offset: const Offset(0.7, 0.3),
                    child: Text(
                      strike.character,
                      style:
                          style.copyWith(color: color.withValues(alpha: 0.35)),
                    ),
                  ),
                  letter,
                ],
              )
            : letter,
      ),
    );
  }
}
