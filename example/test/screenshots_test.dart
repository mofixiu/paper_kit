import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_kit/paper_kit.dart';
import 'package:paper_kit_example/main.dart';
import 'package:paper_kit_example/phone_demo.dart';

final _skip = !Platform.environment.containsKey('PAPER_KIT_SCREENSHOTS');
const _phone = Size(390, 844);

Future<void> _loadFonts() async {
  final montserrat = FontLoader('Montserrat');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('test/fonts/Montserrat-$weight.ttf').readAsBytesSync();
    montserrat.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await montserrat.load();
  const courier = '/System/Library/Fonts/Supplemental/Courier New.ttf';
  if (File(courier).existsSync()) {
    final bytes = File(courier).readAsBytesSync();
    await (FontLoader(
      'Courier Prime',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  }
}

Widget _slip(
  bool dark,
  Widget child, {
  double? width,
  double? height,
  EdgeInsets padding = const EdgeInsets.all(14),
}) {
  return Container(
    width: width,
    height: height,
    padding: padding,
    decoration: BoxDecoration(
      color: PaperPalette.of(dark ? Brightness.dark : Brightness.light).sheet,
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 12,
          spreadRadius: -6,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

Future<void> _settle(WidgetTester tester, [int ms = 2400]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _capture(WidgetTester tester, Key key, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('../doc/screenshots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void _phoneSized(WidgetTester tester) {
  tester.view.physicalSize = _phone * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _scene(Key key, bool dark, Widget child) {
  final theme = PaperThemeData.fromBrightness(
    dark ? Brightness.dark : Brightness.light,
  );
  return RepaintBoundary(
    key: key,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.toMaterialTheme(),
      home: PaperTheme(
        data: theme,
        child: Scaffold(
          body: PaperBackground(child: SafeArea(child: child)),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    PaperHaptics.enabled = false;
    if (!_skip) await _loadFonts();
  });

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('gallery ($mode)', skip: _skip, (tester) async {
      _phoneSized(tester);
      const key = ValueKey('shot');
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: PaperKitGallery(initiallyDark: dark, autoplay: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PaperStampButton).first);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 260));
      await _capture(tester, key, 'gallery-$mode');
      await tester.pumpAndSettle();
    });

    testWidgets('components ($mode)', skip: _skip, (tester) async {
      _phoneSized(tester);
      const key = ValueKey('shot');
      final ticket = GlobalKey<PaperTearToConfirmState>();
      var ticked = true;
      await tester.pumpWidget(
        _scene(
          key,
          dark,
          ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            children: [
              const PaperHeading('paper kit', size: 28),
              const SizedBox(height: 24),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PaperCheckbox(
                      label: 'water the plants',
                      value: ticked,
                      onChanged: (v) => setState(() => ticked = v),
                    ),
                    PaperCheckbox(
                      label: 'post the zine',
                      value: false,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              PaperTearToConfirm(
                key: ticket,
                label: 'admit one · table for two, 8pm',
                onConfirmed: () {},
              ),
              const SizedBox(height: 26),
              const PaperTextField(
                label: 'email',
                hint: 'you@example.com',
                errorText: 'that needs an @',
              ),
              const SizedBox(height: 28),
              PaperRuler(
                value: 7.5,
                min: 4,
                max: 12,
                divisions: 16,
                onChanged: (_) {},
              ),
              const SizedBox(height: 28),
              const PaperZine(
                title: 'how to fold a zine',
                initiallyExpanded: true,
                panelHeight: 56,
                panels: [
                  Text('1 · fold the sheet in half'),
                  Text('2 · fold it in half again'),
                  Text('3 · cut along the middle fold'),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      ticket.currentState!.tear();
      await tester.pumpAndSettle();
      await _capture(tester, key, 'components-$mode');
    });

    testWidgets('desk ($mode)', skip: _skip, (tester) async {
      _phoneSized(tester);
      const key = ValueKey('shot');
      final envelope = GlobalKey<PaperEnvelopeState>();
      final pad = GlobalKey<PaperFlipPadState>();
      await tester.pumpWidget(
        _scene(
          key,
          dark,
          ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            children: [
              const PaperHeading('on the desk', size: 28),
              const SizedBox(height: 14),
              Center(
                child: PaperEnvelope(
                  key: envelope,
                  width: 300,
                  to: 'for tobi',
                  letter: const Text(
                    'dear tobi,\nthe zine swap is on saturday at 3pm.',
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const PaperTypewriter(
                'dear hiring team,\nI build apps in Flutter, by hand.',
                charDelay: Duration(milliseconds: 10),
                seed: 26,
              ),
              const SizedBox(height: 26),
              Center(
                child: PaperFlipPad(
                  key: pad,
                  size: const Size(300, 170),
                  pages: const [
                    Text('monday\nscan the film'),
                    Text('wednesday\nlay out the zine'),
                    Text('friday\nprint run'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      envelope.currentState!.open();
      pad.currentState!.next();
      await _settle(tester);
      await _capture(tester, key, 'desk-$mode');
    });

    testWidgets('office ($mode)', skip: _skip, (tester) async {
      _phoneSized(tester);
      const key = ValueKey('shot');
      await tester.pumpWidget(
        _scene(
          key,
          dark,
          ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            children: [
              const PaperHeading('in the office', size: 28),
              const SizedBox(height: 20),
              PaperHighlightSwitch(
                label: 'remind me on friday',
                value: true,
                onChanged: (_) {},
              ),
              PaperHighlightSwitch(
                label: 'print on recycled paper',
                value: false,
                onChanged: (_) {},
              ),
              const SizedBox(height: 18),
              const PaperRedact(
                'the spare key is under the third plant pot, not the doormat.',
              ),
              const SizedBox(height: 26),
              Center(
                child: PaperPunchCard(
                  title: 'the paper room · coffee',
                  holes: 10,
                  punched: 7,
                  width: 320,
                  onPunch: (_) {},
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: PaperClip(
                  attachment: _slip(
                    dark,
                    const Text('receipt\n£12.40'),
                    padding: const EdgeInsets.fromLTRB(40, 14, 16, 14),
                  ),
                  child: _slip(
                    dark,
                    const Text('october expenses'),
                    width: 300,
                    height: 150,
                    padding: const EdgeInsets.fromLTRB(130, 20, 20, 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PaperCutRule(
                child: _slip(dark, const Text('20% off your next print run')),
              ),
            ],
          ),
        ),
      );
      await _settle(tester, 1200);
      await _capture(tester, key, 'office-$mode');
    });

    testWidgets('phone ($mode)', skip: _skip, (tester) async {
      _phoneSized(tester);
      const key = ValueKey('shot');
      await tester.pumpWidget(
        _scene(
          key,
          dark,
          const Center(child: PhoneDemo(autoplay: false, width: 300)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('water the plants'));
      await tester.pumpAndSettle();
      await _capture(tester, key, 'phone-$mode');
    });
  }
}
