import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_kit/paper_kit.dart';

import 'helpers.dart';

void main() {
  testBoth('the toggle names the theme it switches to', (tester, dark) async {
    bool? changed;
    await pumpPaper(
      tester,
      PaperThemeToggle(isDark: dark, onChanged: (v) => changed = v),
      dark: dark,
    );
    expect(find.text(dark ? 'light' : 'dark'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Switch to ${dark ? 'light' : 'dark'} mode'),
      findsOneWidget,
    );
    await tester.tap(find.byType(PaperThemeToggle));
    expect(changed, !dark);
  });

  testBoth('the stamp leaves an impression that fades', (tester, dark) async {
    var stamped = 0;
    await pumpPaper(
      tester,
      PaperStampButton(label: 'Approved', onPressed: () => stamped++),
      dark: dark,
    );
    expect(find.text('approved'), findsOneWidget);
    await tester.tap(find.byType(PaperStampButton));
    await tester.pump();
    expect(stamped, 1);
    expect(find.byType(PaperStampImpression), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byType(PaperStampImpression), findsNothing);
  });

  testWidgets('the stamp can be pressed from the keyboard', (tester) async {
    var stamped = 0;
    await pumpPaper(
      tester,
      PaperStampButton(label: 'go', onPressed: () => stamped++),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(stamped, 1);
    await tester.pump(const Duration(seconds: 2));
  });

  testBoth('the checkbox ticks and crosses out', (tester, dark) async {
    var value = false;
    await pumpPaper(
      tester,
      StatefulBuilder(
        builder: (context, setState) => PaperCheckbox(
          label: 'call mum',
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
      dark: dark,
    );
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byType(PaperCheckbox)),
      isSemantics(
        label: 'call mum',
        isButton: true,
        hasCheckedState: true,
        isChecked: false,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.text('call mum'));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    await tester.tap(find.byType(PaperCheckbox));
    await tester.pumpAndSettle();
    expect(value, isFalse);
    handle.dispose();
  });

  testBoth('the text field reports changes and shows errors',
      (tester, dark) async {
    String? typed;
    await pumpPaper(
      tester,
      SizedBox(
        width: 300,
        child: PaperTextField(
          label: 'Email',
          hint: 'you@example.com',
          errorText: 'That needs an @',
          onChanged: (v) => typed = v,
        ),
      ),
      dark: dark,
    );
    expect(find.text('email'), findsOneWidget);
    expect(find.text('That needs an @'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ada@example.com');
    await tester.pumpAndSettle();
    expect(typed, 'ada@example.com');
  });

  testBoth('the ruler snaps to its marks', (tester, dark) async {
    var value = 5.0;
    await pumpPaper(
      tester,
      SizedBox(
        width: 328,
        child: StatefulBuilder(
          builder: (context, setState) => PaperRuler(
            value: value,
            divisions: 10,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
      dark: dark,
    );
    final rect = tester.getRect(find.byType(PaperRuler));
    // The usable length is 300 (14 px inset at each end); 7.2 snaps to 7.
    await tester.tapAt(Offset(rect.left + 14 + 300 * 0.72, rect.center.dy));
    await tester.pumpAndSettle();
    expect(value, 7);
    await tester.drag(find.byType(PaperRuler), const Offset(-1000, 0));
    await tester.pumpAndSettle();
    expect(value, 0);
  });

  testWidgets('the ruler is a slider to assistive tech', (tester) async {
    var value = 5.0;
    await pumpPaper(
      tester,
      SizedBox(
        width: 300,
        child: PaperRuler(value: value, onChanged: (v) => value = v),
      ),
    );
    final handle = tester.ensureSemantics();
    expect(tester.getSemantics(find.byType(PaperRuler)).value, '5');
    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(PaperRuler),
            matching: find.byType(Semantics),
          )
          .first,
    );
    semantics.properties.onIncrease!();
    expect(value, 5.5);
    handle.dispose();
  });
}
