import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_kit/paper_kit.dart';
import 'package:paper_kit/src/ink_reveal.dart' show inkBlot;

import 'helpers.dart';

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    return GestureDetector(
      onTap: () => setState(() => count++),
      child: Text(
        '${theme.isDark ? 'dark' : 'light'} $count',
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

void main() {
  testWidgets('ink reveal switches theme and keeps state', (tester) async {
    var dark = false;
    late StateSetter setOuter;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setOuter = setState;
          return MaterialApp(
            builder: (context, child) => PaperInkReveal(
              theme: dark ? PaperThemeData.dark() : PaperThemeData.light(),
              origin: const Offset(10, 10),
              child: child!,
            ),
            home: const Center(child: _Counter()),
          );
        },
      ),
    );
    await tester.tap(find.byType(_Counter));
    await tester.pump();
    expect(find.text('light 1'), findsOneWidget);

    setOuter(() => dark = true);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('dark 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('the ink blot is a closed wobbly circle', () {
    final blot = inkBlot(const Offset(50, 50), 40, 3);
    final bounds = blot.getBounds();
    expect(bounds.width, inInclusiveRange(70, 95));
    expect(blot.contains(const Offset(50, 50)), isTrue);
  });

  testWidgets('the phone frame keeps the iPhone proportions', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: PaperPhoneFrame(
            width: 300,
            child: ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(PaperPhoneFrame));
    expect(size.width, 300);
    const screen = 300 - 2 * 300 * 0.036;
    expect(size.height, closeTo(screen * 1565 / 720 + 2 * 300 * 0.036, 0.01));
    expect(find.text('9:41'), findsOneWidget);
  });

  testWidgets('a demo script taps real widgets and stops on touch',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = PaperDemoController();
    final button = GlobalKey();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PaperPhoneFrame(
            demo: controller,
            child: Center(
              child: GestureDetector(
                key: button,
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(width: 120, height: 60),
              ),
            ),
          ),
        ),
      ),
    );
    final script = PaperDemoScript(
      controller: controller,
      steps: [PaperDemoStep.tapKey(button)],
      pause: const Duration(milliseconds: 200),
      startDelay: Duration.zero,
      loopDelay: const Duration(milliseconds: 300),
    );
    script.play();
    expect(script.isPlaying, isTrue);
    await pumpFrames(tester, const Duration(milliseconds: 1000));
    expect(taps, 1);
    expect(controller.visible, isTrue);

    await tester.tapAt(
        tester.getCenter(find.byType(PaperPhoneFrame)) + const Offset(0, 150));
    await tester.pump();
    expect(script.isPlaying, isFalse);
    expect(controller.visible, isFalse);
    await pumpFrames(tester, const Duration(seconds: 2));
    expect(taps, 1);
    controller.dispose();
  });

  testWidgets('the fingertip can drag what is under it', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = PaperDemoController();
    var dragged = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PaperPhoneFrame(
            demo: controller,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) => dragged += d.delta.dx,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    controller.moveTo(const Offset(0.3, 0.5), duration: Duration.zero);
    await tester.pump();
    final done = controller.drag(const Offset(100, 0));
    await tester.pump();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await done;
    expect(dragged, greaterThan(50));
    controller.dispose();
  });
}
