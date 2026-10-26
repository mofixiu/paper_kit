import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_kit/paper_kit.dart';

import 'helpers.dart';

/// Records the haptic calls the widgets make.
List<String> recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add('${call.arguments}');
      }
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}

void main() {
  testBoth('the highlight switch toggles with a stroke', (tester, dark) async {
    final haptics = recordHaptics(tester);
    var on = false;
    await pumpPaper(
      tester,
      StatefulBuilder(
        builder: (context, setState) => PaperHighlightSwitch(
          label: 'remind me on friday',
          value: on,
          onChanged: (value) => setState(() => on = value),
        ),
      ),
      dark: dark,
    );
    expect(
        tester.getSemantics(find.byType(PaperHighlightSwitch)),
        matchesSemantics(
            isToggled: false,
            hasToggledState: true,
            isButton: true,
            hasTapAction: true,
            label: 'remind me on friday'));
    await tester.tap(find.text('remind me on friday'));
    await pumpFrames(tester, const Duration(milliseconds: 400));
    expect(on, isTrue);
    expect(haptics, contains('HapticFeedbackType.selectionClick'));
    await tester.tap(find.text('remind me on friday'));
    await pumpFrames(tester, const Duration(milliseconds: 300));
    expect(on, isFalse);
  });

  testBoth('redacted text is hidden until tapped', (tester, dark) async {
    final changes = <bool>[];
    await pumpPaper(
      tester,
      SizedBox(
        width: 260,
        child: PaperRedact(
          'the password is under the stapler, not the plant',
          onChanged: changes.add,
        ),
      ),
      dark: dark,
    );
    expect(
        find.bySemanticsLabel('Redacted text. Tap to reveal.'), findsOneWidget);
    await tester.tap(find.byType(PaperRedact));
    await pumpFrames(tester, const Duration(milliseconds: 700));
    expect(changes, [false]);
    expect(
        find.bySemanticsLabel(
            'the password is under the stapler, not the plant'),
        findsOneWidget);
    await tester.tap(find.byType(PaperRedact));
    await pumpFrames(tester, const Duration(milliseconds: 700));
    expect(changes, [false, true]);
  });

  testBoth('the punch card punches one hole per tap, then stops',
      (tester, dark) async {
    final haptics = recordHaptics(tester);
    var punched = 2;
    await pumpPaper(
      tester,
      StatefulBuilder(
        builder: (context, setState) => PaperPunchCard(
          title: 'Coffee card',
          holes: 4,
          punched: punched,
          reward: 'free one',
          onPunch: (count) => setState(() => punched = count),
        ),
      ),
      dark: dark,
    );
    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('coffee card'), findsOneWidget);
    await tester.tap(find.byType(PaperPunchCard));
    await pumpFrames(tester, const Duration(milliseconds: 200));
    expect(find.text('3 / 4'), findsOneWidget);
    expect(haptics, contains('HapticFeedbackType.heavyImpact'));
    await tester.tap(find.byType(PaperPunchCard));
    await pumpFrames(tester, const Duration(milliseconds: 800));
    expect(punched, 4);
    expect(find.byType(PaperStampImpression), findsOneWidget);
    await tester.tap(find.byType(PaperPunchCard));
    await pumpFrames(tester, const Duration(milliseconds: 100));
    expect(punched, 4);
  });

  testBoth('the paperclip lets go of the slip and clips it back',
      (tester, dark) async {
    final states = <bool>[];
    await pumpPaper(
      tester,
      PaperClip(
        onChanged: states.add,
        attachment:
            const SizedBox(width: 90, height: 60, child: Text('receipt')),
        child: const SizedBox(width: 220, height: 140, child: Text('expenses')),
      ),
      dark: dark,
    );
    final before = tester.getTopLeft(find.text('receipt'));
    await tester.tap(find.text('expenses'));
    await pumpFrames(tester, const Duration(milliseconds: 600));
    expect(tester.getTopLeft(find.text('receipt')).dy,
        greaterThan(before.dy + 40));
    await tester.tap(find.text('expenses'));
    await pumpFrames(tester, const Duration(milliseconds: 600));
    expect(states, [false, true]);
    expect((tester.getTopLeft(find.text('receipt')) - before).distance,
        lessThan(1));
  });

  testBoth('the cut rule cuts when tapped or dragged to the end',
      (tester, dark) async {
    var cuts = 0;
    final rule = GlobalKey<PaperCutRuleState>();
    await pumpPaper(
      tester,
      SizedBox(
        width: 300,
        child: PaperCutRule(
          key: rule,
          onCut: () => cuts++,
          child: const SizedBox(height: 80, child: Text('20% off')),
        ),
      ),
      dark: dark,
    );
    await tester.drag(find.byType(CustomPaint).last, const Offset(80, 0));
    await pumpFrames(tester, const Duration(milliseconds: 100));
    expect(rule.currentState!.isCut, isFalse);
    await tester.drag(find.byType(CustomPaint).last, const Offset(260, 0));
    await pumpFrames(tester, const Duration(milliseconds: 700));
    expect(cuts, 1);
    rule.currentState!.reset();
    await tester.pump();
    expect(rule.currentState!.isCut, isFalse);
    rule.currentState!.cut();
    await pumpFrames(tester, const Duration(milliseconds: 1900));
    expect(cuts, 2);
  });

  testWidgets('haptics play the patterns, and can be turned off',
      (tester) async {
    final haptics = recordHaptics(tester);
    await tester.runAsync(PaperHaptics.stamp);
    expect(haptics,
        ['HapticFeedbackType.heavyImpact', 'HapticFeedbackType.lightImpact']);
    haptics.clear();
    await tester.runAsync(PaperHaptics.tear);
    expect(haptics.where((h) => h == 'HapticFeedbackType.selectionClick'),
        hasLength(7));
    expect(haptics.last, 'HapticFeedbackType.mediumImpact');
    haptics.clear();
    PaperHaptics.enabled = false;
    addTearDown(() => PaperHaptics.enabled = true);
    await tester.runAsync(PaperHaptics.punch);
    expect(haptics, isEmpty);
  });
}
