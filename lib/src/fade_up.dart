import 'package:flutter/widgets.dart';

import 'motion.dart';

/// The kit's screen transition: the child fades in while rising 1.8% of its height
/// and growing from 98.5% to full size.
class PaperFadeUpTransition extends StatelessWidget {
  /// Animates [child] in as [animation] runs from 0 to 1.
  const PaperFadeUpTransition({
    super.key,
    required this.animation,
    required this.child,
    this.curve = PaperMotion.fadeUp,
  });

  /// Drives the transition; 1 is fully in place.
  final Animation<double> animation;

  /// The curve applied to [animation].
  final Curve curve;

  /// What fades up.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = curve.transform(animation.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: FractionalTranslation(
            translation: Offset(0, 0.018 * (1 - t)),
            child: Transform.scale(scale: 0.985 + 0.015 * t, child: child),
          ),
        );
      },
    );
  }
}

/// A page route that fades the new page up into place, and dims the page beneath
/// it a little.
class PaperFadeUpRoute<T> extends PageRoute<T> {
  /// A route showing the page that [builder] builds.
  PaperFadeUpRoute({
    required this.builder,
    super.settings,
    this.maintainState = true,
    super.fullscreenDialog,
  });

  /// Builds the page.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  @override
  Duration get transitionDuration => PaperMotion.fadeUpDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.94).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: PaperMotion.inOut),
      ),
      child: PaperFadeUpTransition(animation: animation, child: child),
    );
  }
}
