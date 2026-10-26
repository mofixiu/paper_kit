import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_kit/paper_kit.dart';

import 'helpers.dart';

void main() {
  test('the palettes carry the portfolio colours', () {
    expect(PaperPalette.light.paper, const Color(0xFFF4ECDE));
    expect(PaperPalette.light.ink, const Color(0xFF211E19));
    expect(PaperPalette.light.muted, const Color(0xFF6B6256));
    expect(PaperPalette.dark.paper, const Color(0xFF171512));
    expect(PaperPalette.dark.redPen, const Color(0xFFE0715C));
    expect(PaperPalette.light.tones, hasLength(7));
    expect(PaperPalette.of(Brightness.dark), same(PaperPalette.dark));
  });

  test('theme data compares by value and builds matching Material themes', () {
    expect(PaperThemeData.light(), PaperThemeData.light());
    expect(PaperThemeData.light(), isNot(PaperThemeData.dark()));
    expect(
      PaperThemeData.light().copyWith(grain: false).grain,
      isFalse,
    );
    final material = PaperThemeData.dark().toMaterialTheme();
    expect(material.brightness, Brightness.dark);
    expect(material.scaffoldBackgroundColor, PaperPalette.dark.paper);
    expect(material.colorScheme.primary, PaperPalette.dark.primary);
  });

  test('text styles go through the font builder', () {
    final theme = PaperThemeData.light(
      fontBuilder: (style) => style.copyWith(fontFamily: 'Custom'),
    );
    final style = theme.text(size: 20, weight: FontWeight.w700);
    expect(style.fontFamily, 'Custom');
    expect(style.fontSize, 20);
    expect(style.color, PaperPalette.light.ink);
    expect(
      theme.toMaterialTheme().textTheme.bodyMedium?.fontFamily,
      'Custom',
    );
  });

  testWidgets('PaperTheme.of falls back to the Material brightness',
      (tester) async {
    late PaperThemeData found;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            found = PaperTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(found.isDark, isTrue);
  });

  testBoth('the background paints paper and grain', (tester, dark) async {
    await pumpPaper(tester, const PaperHeading('Hello'), dark: dark);
    expect(find.byType(PaperBackground), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the heading is lowercase with a bar', (tester) async {
    await pumpPaper(tester, const PaperHeading('Work Experience'));
    expect(find.text('work experience'), findsOneWidget);
    final bar = tester.getSize(
      find.descendant(
        of: find.byType(PaperHeading),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(bar, const Size(40, 3));
  });

  testWidgets('the fade-up route fades in and out', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const Text('first')),
    );
    navigator.currentState!.push(
      PaperFadeUpRoute<void>(builder: (_) => const Text('second')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('second'), matching: find.byType(Opacity))
          .first,
    );
    expect(opacity.opacity, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('second'), findsNothing);
  });
}
