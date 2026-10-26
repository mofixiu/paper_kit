import 'package:flutter/widgets.dart';

import 'fade_up.dart';
import 'internal/pressable.dart';
import 'motion.dart';
import 'theme.dart';

/// One section of a [PaperIndexTabs] page.
@immutable
class PaperTab {
  /// A tab named [label], coloured [tone], showing [child] when selected.
  const PaperTab({
    required this.label,
    required this.tone,
    required this.child,
  });

  /// The word on the tab. It is shown in lowercase.
  final String label;

  /// The tab's colour, usually one of [PaperPalette.tones].
  final Color tone;

  /// The page shown while this tab is selected.
  final Widget child;
}

/// A notebook page with coloured index tabs sticking out of its right edge.
///
/// The selected tab comes forward and sticks out further; the page fades up to
/// show its content.
class PaperIndexTabs extends StatelessWidget {
  /// A page with [tabs], showing the one at [selectedIndex].
  const PaperIndexTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.padding = const EdgeInsets.all(24),
  }) : assert(tabs.length > 0);

  /// The sections, from the top tab down.
  final List<PaperTab> tabs;

  /// Which tab is open.
  final int selectedIndex;

  /// Called with a tab's index when it's tapped.
  final ValueChanged<int> onChanged;

  /// Space around the page content.
  final EdgeInsets padding;

  static const double _tabWidth = 30;
  static const double _tabHeight = 76;
  static const double _gap = 6;
  static const double _top = 16;
  static const double _tuck = 6;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final palette = theme.palette;
    final selected = selectedIndex.clamp(0, tabs.length - 1);
    final minHeight = _top + tabs.length * (_tabHeight + _gap) + 10;
    final shadow =
        palette.isDark ? const Color(0x80000000) : const Color(0x22281A0E);

    Widget tab(int index) {
      final isSelected = index == selected;
      final stickOut = isSelected ? _tabWidth : 22.0;
      final data = tabs[index];
      return AnimatedPositioned(
        key: ValueKey<int>(index),
        duration: const Duration(milliseconds: 220),
        curve: PaperMotion.fadeUp,
        top: _top + index * (_tabHeight + _gap),
        right: _tabWidth - stickOut,
        width: _tabWidth + _tuck,
        height: _tabHeight,
        child: Pressable(
          semanticLabel: data.label,
          selected: isSelected,
          focusInset: -2,
          onTap: () => onChanged(index),
          builder: (context, state) => AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: isSelected || state.hovered ? 1 : 0.8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: data.tone,
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(8)),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: shadow,
                          blurRadius: 6,
                          offset: const Offset(2, 2),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: _tuck),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      data.label.toLowerCase(),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: theme.text(
                        size: 11,
                        weight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: palette.tabInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final page = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.sheet,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: palette.rule.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: shadow,
              blurRadius: 18,
              spreadRadius: -6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: AnimatedSwitcher(
            duration: PaperMotion.fadeUpDuration,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            transitionBuilder: (child, animation) =>
                PaperFadeUpTransition(animation: animation, child: child),
            child: KeyedSubtree(
              key: ValueKey<int>(selected),
              child: tabs[selected].child,
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < tabs.length; i++)
          if (i != selected) tab(i),
        Padding(padding: const EdgeInsets.only(right: _tabWidth), child: page),
        tab(selected),
      ],
    );
  }
}
