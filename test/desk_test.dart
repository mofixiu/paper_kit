import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_kit/paper_kit.dart';

import 'helpers.dart';

void main() {
  testBoth('the envelope opens, then closes again', (tester, dark) async {
    var opened = 0;
    var closed = 0;
    final envelope = GlobalKey<PaperEnvelopeState>();
    await pumpPaper(
      tester,
      PaperEnvelope(
        key: envelope,
        to: 'tobi',
        letter: const Text('see you saturday'),
        onOpened: () => opened++,
        onClosed: () => closed++,
      ),
      dark: dark,
    );
    expect(find.text('tobi'), findsOneWidget);
    expect(envelope.currentState!.isOpen, isFalse);
    await tester.tap(find.byType(PaperEnvelope));
    await pumpFrames(tester, const Duration(milliseconds: 1600));
    expect(opened, 1);
    expect(envelope.currentState!.isOpen, isTrue);
    expect(find.text('see you saturday'), findsOneWidget);
    await tester.tap(find.byType(PaperEnvelope));
    await pumpFrames(tester, const Duration(milliseconds: 1600));
    expect(closed, 1);
  });

  testBoth('the shredder cuts the page into strips', (tester, dark) async {
    var shredded = 0;
    final shredder = GlobalKey<PaperShredderState>();
    await pumpPaper(
      tester,
      PaperShredder(
        key: shredder,
        strips: 8,
        onShredded: () => shredded++,
        child: const SizedBox(width: 200, height: 120, child: Text('draft')),
      ),
      dark: dark,
    );
    final before = tester.getSize(find.byType(PaperShredder));
    shredder.currentState!.shred();
    await pumpFrames(tester, const Duration(milliseconds: 1000));
    expect(find.text('draft'), findsNWidgets(9));
    expect(tester.getSize(find.byType(PaperShredder)), before);
    await pumpFrames(tester, const Duration(milliseconds: 1100));
    expect(shredded, 1);
    expect(shredder.currentState!.isShredded, isTrue);
    shredder.currentState!.reset();
    await tester.pump();
    expect(find.text('draft'), findsOneWidget);
  });

  testBoth('the typewriter types every key, then calls back',
      (tester, dark) async {
    var done = 0;
    await pumpPaper(
      tester,
      PaperTypewriter(
        'dear tobi,\nsee you sat.',
        charDelay: const Duration(milliseconds: 20),
        onDone: () => done++,
      ),
      dark: dark,
    );
    await pumpFrames(tester, const Duration(milliseconds: 120));
    expect(find.text('d'), findsOneWidget);
    expect(find.text('.'), findsNothing);
    await pumpFrames(tester, const Duration(milliseconds: 500));
    expect(find.text('.'), findsWidgets);
    expect(done, 1);
    expect(find.bySemanticsLabel('dear tobi,\nsee you sat.'), findsOneWidget);
  });

  testBoth('the flip pad turns pages both ways', (tester, dark) async {
    final pages = <int>[];
    final pad = GlobalKey<PaperFlipPadState>();
    await pumpPaper(
      tester,
      PaperFlipPad(
        key: pad,
        onPageChanged: pages.add,
        pages: const [Text('mon'), Text('tue'), Text('wed')],
      ),
      dark: dark,
    );
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.byType(PaperFlipPad));
    await pumpFrames(tester, const Duration(milliseconds: 800));
    expect(pad.currentState!.page, 1);
    expect(find.text('tue'), findsOneWidget);
    await tester.fling(find.byType(PaperFlipPad), const Offset(0, -120), 800);
    await pumpFrames(tester, const Duration(milliseconds: 800));
    expect(pad.currentState!.page, 2);
    await tester.tap(find.byType(PaperFlipPad));
    await pumpFrames(tester, const Duration(milliseconds: 800));
    expect(pad.currentState!.page, 2);
    await tester.fling(find.byType(PaperFlipPad), const Offset(0, 120), 800);
    await pumpFrames(tester, const Duration(milliseconds: 800));
    expect(pages, [1, 2, 1]);
  });
}
