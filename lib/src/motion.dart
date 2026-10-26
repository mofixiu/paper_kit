import 'package:flutter/animation.dart';

/// Curves and durations shared by every widget in the kit.
///
/// They mirror the motion of the apps the kit came from: a quick fade-up for new
/// screens, a short crossfade for tabs and the standard bottom-sheet slide.
abstract final class PaperMotion {
  /// Ease-out cubic, used for anything arriving on screen.
  static const Curve fadeUp = Cubic(0.215, 0.61, 0.355, 1);

  /// Ease-in-out cubic, used for things that move in place.
  static const Curve inOut = Cubic(0.645, 0.045, 0.355, 1);

  /// Material's decelerate curve, used for sheets.
  static const Curve decelerate = Cubic(0, 0, 0.2, 1);

  /// The fingertip cursor's glide between taps.
  static const Curve fingertip = Cubic(0.45, 0, 0.2, 1);

  /// The ink blot that spreads when the theme changes.
  static const Curve ink = Cubic(0.65, 0, 0.35, 1);

  /// A new screen fading up into place.
  static const Duration fadeUpDuration = Duration(milliseconds: 300);

  /// Switching tabs.
  static const Duration tabDuration = Duration(milliseconds: 280);

  /// A bottom sheet sliding up.
  static const Duration sheetDuration = Duration(milliseconds: 440);
}
