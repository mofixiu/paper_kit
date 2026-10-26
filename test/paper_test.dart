import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_kit/paper_kit.dart';

import 'helpers.dart';

void main() {
  testBoth('index tabs switch pages', (tester, dark) async {
    var selected = 0;
    await pumpPaper(
      tester,
      SizedBox(
        width: 320,
        child: StatefulBuilder(
          builder: (context, setState) => PaperIndexTabs(
            selectedIndex: selected,
            onChanged: (i) => setState(() => selected = i),
            tabs: const [
              PaperTab(
                  label: 'Today', tone: Colors.orange, child: Text('plans')),
              PaperTab(label: 'Week', tone: Colors.green, child: Text('days')),
            ],
          ),
        ),
      ),
      dark: dark,
    );
    expect(find.text('today'), findsOneWidget);
    expect(find.text('plans'), findsOneWidget);
    await tester.tap(find.text('week'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('days'), findsOneWidget);
    expect(find.text('plans'), findsNothing);
  });

  group('tear to confirm', () {
    Future<GlobalKey<PaperTearToConfirmState>> pumpTicket(
      WidgetTester tester, {
      required VoidCallback onConfirmed,
      VoidCallback? onReset,
      bool dark = false,
    }) async {
      final key = GlobalKey<PaperTearToConfirmState>();
      await pumpPaper(
        tester,
        SizedBox(
          width: 320,
          child: PaperTearToConfirm(
            key: key,
            label: 'Admit one',
            onConfirmed: onConfirmed,
            onReset: onReset,
          ),
        ),
        dark: dark,
      );
      return key;
    }

    Offset stub(WidgetTester tester) {
      final rect = tester.getRect(find.byType(PaperTearToConfirm));
      return Offset(rect.left + rect.width * 0.86, rect.center.dy);
    }

    testBoth('tears off when pulled far enough', (tester, dark) async {
      var confirmed = 0;
      final key =
          await pumpTicket(tester, onConfirmed: () => confirmed++, dark: dark);
      await tester.dragFrom(stub(tester), const Offset(120, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(key.currentState!.isTorn, isTrue);
      expect(confirmed, 0);
      await tester.pumpAndSettle();
      expect(confirmed, 1);
      expect(find.byType(PaperStampImpression), findsOneWidget);
    });

    testWidgets('springs back when let go early', (tester) async {
      var confirmed = 0;
      final key = await pumpTicket(tester, onConfirmed: () => confirmed++);
      await tester.dragFrom(stub(tester), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(key.currentState!.isTorn, isFalse);
      expect(confirmed, 0);
    });

    testWidgets('reset puts the stub back', (tester) async {
      var reset = 0;
      final key = await pumpTicket(
        tester,
        onConfirmed: () {},
        onReset: () => reset++,
      );
      key.currentState!.tear();
      await tester.pumpAndSettle();
      expect(key.currentState!.isTorn, isTrue);
      key.currentState!.reset();
      await tester.pumpAndSettle();
      expect(key.currentState!.isTorn, isFalse);
      expect(reset, 1);
      expect(find.byType(PaperStampImpression), findsNothing);
    });
  });

  testBoth('a receipt prints, holds and tears off', (tester, dark) async {
    late BuildContext context;
    await pumpPaper(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
      dark: dark,
    );
    var gone = false;
    PaperReceipt.show(
      context,
      title: 'Order #2041',
      lines: const [PaperReceiptLine('Total', '6,300.00')],
      footer: 'thank you',
      hold: const Duration(seconds: 1),
    ).then((_) => gone = true);
    await tester.pump();
    expect(find.text('order #2041'), findsOneWidget);
    expect(find.text('6,300.00'), findsOneWidget);
    await pumpFrames(tester, const Duration(milliseconds: 950));
    expect(gone, isFalse);
    await pumpFrames(tester, const Duration(milliseconds: 1500));
    expect(gone, isTrue);
    expect(find.text('order #2041'), findsNothing);
  });

  testWidgets('tapping a receipt tears it off early', (tester) async {
    late BuildContext context;
    await pumpPaper(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    var gone = false;
    PaperReceipt.show(
      context,
      title: 'Saved',
      lines: const [],
      hold: const Duration(minutes: 1),
    ).then((_) => gone = true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('saved'));
    await tester.pumpAndSettle();
    expect(gone, isTrue);
  });

  testBoth('the paper plane flies off and comes back', (tester, dark) async {
    var sent = 0;
    await pumpPaper(
      tester,
      PaperPlaneButton(onSent: () => sent++),
      dark: dark,
    );
    expect(find.text('send'), findsOneWidget);
    await tester.tap(find.byType(PaperPlaneButton));
    await pumpFrames(tester, const Duration(milliseconds: 400));
    expect(sent, 0);
    await pumpFrames(tester, const Duration(milliseconds: 800));
    expect(sent, 1);
    expect(find.text('sent'), findsOneWidget);
    await pumpFrames(tester, const Duration(milliseconds: 2000));
    // Ready to send again.
    await tester.tap(find.byType(PaperPlaneButton));
    await pumpFrames(tester, const Duration(milliseconds: 1200));
    expect(sent, 2);
    await pumpFrames(tester, const Duration(milliseconds: 2000));
  });

  group('peel', () {
    testBoth('peels off past halfway', (tester, dark) async {
      var peeled = 0;
      await pumpPaper(
        tester,
        PaperPeel(onPeeled: () => peeled++, child: const Text('buy stamps')),
        dark: dark,
      );
      final rect = tester.getRect(find.byType(PaperPeel));
      await tester.dragFrom(
        rect.bottomRight - const Offset(6, 6),
        const Offset(-170, -170),
      );
      await tester.pumpAndSettle();
      expect(peeled, 1);
      expect(find.text('buy stamps'), findsNothing);
    });

    testWidgets('lies flat again when let go early', (tester) async {
      var peeled = 0;
      final key = GlobalKey<PaperPeelState>();
      await pumpPaper(
        tester,
        PaperPeel(
          key: key,
          onPeeled: () => peeled++,
          child: const Text('note'),
        ),
      );
      final rect = tester.getRect(find.byType(PaperPeel));
      await tester.dragFrom(
        rect.bottomRight - const Offset(6, 6),
        const Offset(-40, -40),
      );
      await tester.pumpAndSettle();
      expect(peeled, 0);
      expect(key.currentState!.isPeeled, isFalse);
      key.currentState!.peel();
      await tester.pumpAndSettle();
      expect(peeled, 1);
      key.currentState!.reset();
      await tester.pump();
      expect(find.text('note'), findsOneWidget);
    });
  });

  testBoth('the zine unfolds and folds', (tester, dark) async {
    await pumpPaper(
      tester,
      const SizedBox(
        width: 320,
        child: PaperZine(
          title: 'How to fold',
          panels: [Text('one'), Text('two'), Text('three')],
        ),
      ),
      dark: dark,
    );
    expect(find.text('how to fold'), findsOneWidget);
    expect(find.text('one'), findsNothing);
    final folded = tester.getSize(find.byType(PaperZine)).height;
    await tester.tap(find.text('how to fold'));
    await tester.pumpAndSettle();
    expect(find.text('three'), findsOneWidget);
    expect(tester.getSize(find.byType(PaperZine)).height, folded + 72 * 3);
    await tester.tap(find.text('how to fold'));
    await tester.pumpAndSettle();
    expect(find.text('one'), findsNothing);
  });

  testBoth('the note shows its child and lifts', (tester, dark) async {
    await pumpPaper(
      tester,
      const PaperNote(child: Text('taped')),
      dark: dark,
    );
    expect(find.text('taped'), findsOneWidget);
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('taped')));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
