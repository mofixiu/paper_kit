import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_kit/paper_kit.dart';

/// Pumps [child] on paper, centred, inside a MaterialApp.
Future<void> pumpPaper(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
}) {
  final theme = PaperThemeData.fromBrightness(
    dark ? Brightness.dark : Brightness.light,
  );
  return tester.pumpWidget(
    MaterialApp(
      theme: theme.toMaterialTheme(),
      home: PaperTheme(
        data: theme,
        child: Scaffold(
          body: PaperBackground(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Runs [body] once in light and once in dark.
void testBoth(
  String description,
  Future<void> Function(WidgetTester tester, bool dark) body,
) {
  for (final dark in [false, true]) {
    testWidgets('$description (${dark ? 'dark' : 'light'})',
        (tester) => body(tester, dark));
  }
}

/// Pumps frames 16 ms apart for [total], so animations started along the way run.
Future<void> pumpFrames(WidgetTester tester, Duration total) async {
  const frame = Duration(milliseconds: 16);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(frame);
    elapsed += frame;
  }
}
