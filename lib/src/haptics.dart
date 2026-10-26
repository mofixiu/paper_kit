import 'package:flutter/services.dart';

/// What paper feels like, as haptic patterns. Each one is a short sequence of the
/// platform's impacts and clicks, timed to the motion the widgets make: a stamp is
/// a heavy thud and a light lift, a tear is a run of clicks along the perforation.
///
/// The kit's widgets call these themselves. Use them in your own widgets too:
///
/// ```dart
/// onPressed: () {
///   PaperHaptics.punch();
///   punchNextHole();
/// }
/// ```
abstract final class PaperHaptics {
  /// Turns every pattern off, for example when the user has turned off haptics.
  static bool enabled = true;

  /// A rubber stamp: a heavy thud, then a light lift.
  static Future<void> stamp() => _play([_heavy, _wait(70), _light]);

  /// A perforation tearing: a quick run of clicks, then a give.
  static Future<void> tear() => _play([
        for (var i = 0; i < 7; i++) ...[_click, _wait(24)],
        _medium,
      ]);

  /// A hole punch going through.
  static Future<void> punch() => _play([_heavy]);

  /// A page flipping over: the lift, then the page landing.
  static Future<void> flip() => _play([_light, _wait(260), _click]);

  /// One snip of the scissors.
  static Future<void> snip() => _play([_click]);

  /// A paperclip snapping onto paper.
  static Future<void> clip() => _play([_medium, _wait(40), _click]);

  /// A wax seal cracking.
  static Future<void> crack() => _play([_medium, _wait(30), _light]);

  /// A highlighter or marker dragged across a line.
  static Future<void> stroke() => _play([_click, _wait(60), _click]);

  /// Paper being crumpled: a scatter of small clicks.
  static Future<void> crinkle() => _play([
        _click,
        _wait(30),
        _click,
        _wait(55),
        _light,
        _wait(25),
        _click,
        _wait(70),
        _click,
        _wait(35),
        _light,
      ]);

  static Future<void> _play(List<Future<void> Function()> steps) async {
    if (!enabled) return;
    for (final step in steps) {
      await step();
    }
  }

  static Future<void> _heavy() => HapticFeedback.heavyImpact();
  static Future<void> _medium() => HapticFeedback.mediumImpact();
  static Future<void> _light() => HapticFeedback.lightImpact();
  static Future<void> _click() => HapticFeedback.selectionClick();
  static Future<void> Function() _wait(int ms) =>
      () => Future<void>.delayed(Duration(milliseconds: ms));
}
