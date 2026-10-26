# paper_kit

**Ink on paper, for Flutter.** A UI kit of handmade-paper widgets: rubber stamps that
leave a red impression, tickets you tear to confirm, receipts that print out of the
top of the screen, sticky notes you peel by the corner, a send button that folds into
a paper plane, an envelope with a wax seal, a typewriter, a shredder, a punch card,
a highlighter, a marker for redacting, a paperclip and scissors, haptics that feel like
paper, and an iPhone frame with a fingertip that taps through your app by itself.

See every widget live, with its code, at **[kit.mofiyinebo.com](https://kit.mofiyinebo.com)**.

<p>
  <img src="https://raw.githubusercontent.com/mofixiu/paper_kit/main/doc/screenshots/gallery-light.png" width="260" alt="The paper_kit gallery on cream paper">
  <img src="https://raw.githubusercontent.com/mofixiu/paper_kit/main/doc/screenshots/gallery-dark.png" width="260" alt="The paper_kit gallery on espresso paper">
</p>
<p>
  <img src="https://raw.githubusercontent.com/mofixiu/paper_kit/main/doc/screenshots/desk-light.png" width="260" alt="An opened envelope, a typed letter and a flip pad">
  <img src="https://raw.githubusercontent.com/mofixiu/paper_kit/main/doc/screenshots/office-light.png" width="260" alt="A highlighter switch, redacted text, a punch card, a paperclip and a cut line">
</p>

- No dependencies beyond Flutter, and no image assets: the paper grain is drawn in code.
- Light (cream `#f4ecde`) and dark (espresso `#171512`) palettes.
- Every control works with a keyboard and a screen reader.

## Install

```sh
flutter pub add paper_kit
```

The widgets ask for **Montserrat**. The kit doesn't bundle fonts, so either add it
with [google_fonts](https://pub.dev/packages/google_fonts):

```dart
final paper = PaperThemeData.light(
  fontBuilder: (style) => GoogleFonts.montserrat(textStyle: style),
);
```

or register it as an asset named `Montserrat` in your `pubspec.yaml`, or pass any
other `fontFamily` to `PaperThemeData`.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:paper_kit/paper_kit.dart';

void main() => runApp(const NotebookApp());

class NotebookApp extends StatefulWidget {
  const NotebookApp({super.key});

  @override
  State<NotebookApp> createState() => _NotebookAppState();
}

class _NotebookAppState extends State<NotebookApp> {
  bool _dark = false;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Applies the theme, and spreads a new palette over the old one like ink.
      builder: (context, child) => PaperInkReveal(
        theme: _dark ? PaperThemeData.dark() : PaperThemeData.light(),
        child: child!,
      ),
      home: Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                PaperThemeToggle(
                  isDark: _dark,
                  onChanged: (dark) => setState(() => _dark = dark),
                ),
                const SizedBox(height: 24),
                const PaperHeading('today'),
                const SizedBox(height: 16),
                PaperCheckbox(
                  label: 'water the plants',
                  value: _done,
                  onChanged: (done) => setState(() => _done = done),
                ),
                const SizedBox(height: 24),
                PaperStampButton(label: 'approved', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## Widgets

| Widget | What it does |
| --- | --- |
| `PaperTheme`, `PaperThemeData`, `PaperPalette` | Colours and type for the kit; `toMaterialTheme()` matches Material widgets to it. |
| `PaperInkReveal` | Themes an app and lets a new palette soak over the old one like ink. |
| `PaperBackground` | Paper colour with a fine procedural grain, or your own texture. |
| `PaperHeading` | A lowercase bold heading with a short bar beneath it. |
| `PaperThemeToggle` | "dark" / "light" in words, with a half-inked dot that turns over. |
| `PaperStampButton` | A rubber stamp that leaves a fading red impression of its label. |
| `PaperStampImpression` | The impression on its own, to place anywhere. |
| `PaperCheckbox` | A hand-drawn box with a scribbled tick that crosses out its label. |
| `PaperTextField` | A field on a ruled line; errors become a wavy red-pen underline. |
| `PaperIndexTabs`, `PaperTab` | A notebook page with coloured index tabs on its edge. |
| `PaperTearToConfirm` | A ticket you confirm by tearing off the stub. |
| `PaperReceipt` | A receipt; `PaperReceipt.show` prints one as a toast and tears it off. |
| `PaperPlaneButton` | A send button that folds into a paper plane and flies away. |
| `PaperPeel` | A sticky note you peel off by dragging its corner. |
| `PaperZine` | A concertina-folded list whose panels unfold one by one. |
| `PaperNote` | A card held on with washi tape, a little crooked. |
| `PaperRuler` | A slider drawn as a paper ruler, snapping to its marks. |
| `PaperEnvelope` | A sealed envelope: tap to crack the wax, swing the flap open and slide the letter out. |
| `PaperShredder` | Feeds what it holds into a strip-cut shredder; the strips curl apart and fall. |
| `PaperTypewriter` | Types text a key at a time, each letter a little off the line and unevenly inked. |
| `PaperFlipPad` | A wire-bound pad whose pages flip up over the rings, like a desk calendar. |
| `PaperHighlightSwitch` | A switch that drags a streaky highlighter across its label. |
| `PaperRedact` | Text blacked out with a marker, line by line, until you tap it. |
| `PaperPunchCard` | A loyalty card: each tap punches a real hole and the disc tumbles out. |
| `PaperClip` | A slip held to a card with a wire paperclip; tap to slide it out. |
| `PaperCutRule` | A dashed "cut here" line; drag the scissors along it and the coupon comes away. |
| `PaperHaptics` | Haptic patterns that feel like paper: stamp, tear, punch, flip, snip and more. |
| `PaperPhoneFrame` | An iPhone drawn in code, to show an app on a page. |
| `PaperFingertip`, `PaperDemoController`, `PaperDemoScript`, `PaperDemoStep` | A scripted fingertip that taps and drags the real widgets on screen, and stops when someone touches it. |
| `PaperFadeUpRoute`, `PaperFadeUpTransition` | The kit's screen transition: fade in while rising 1.8%. |
| `PaperMotion` | The kit's curves and durations. |

## Theming

`PaperThemeData` holds a `PaperPalette` (paper, sheet, ink, muted, faint, rule,
accent, primary, red pen, blue ink, sticky note and seven tab tones), a `fontFamily`,
and whether to draw the grain. Use the presets or adjust one:

```dart
final theme = PaperThemeData.light().copyWith(
  palette: PaperPalette.light.copyWith(redPen: const Color(0xFFC0392B)),
  grain: false,
);
```

Wrap a subtree in `PaperTheme(data: theme, child: ...)`, or the whole app in
`PaperInkReveal`. Without either, widgets follow the brightness of the Material
`Theme`. Every text style comes from `theme.text(...)`, so your own widgets can match.

## A phone that demos itself

```dart
final fingertip = PaperDemoController();
final stamp = GlobalKey();

PaperPhoneFrame(
  width: 280,
  demo: fingertip,
  child: Center(child: PaperStampButton(key: stamp, label: 'filed', onPressed: save)),
);

PaperDemoScript(
  controller: fingertip,
  steps: [PaperDemoStep.tapKey(stamp), PaperDemoStep.wait(const Duration(seconds: 1))],
).play();
```

The fingertip sends real pointer events, so taps and drags go to your widgets. They
carry the device id `kPaperDemoPointerDevice`; any other touch on the frame stops
the script.

## Example

`example/` is a gallery of every widget in light and dark. Run it with:

```sh
cd example
flutter create . --platforms=web,ios,android
flutter run
```

## Licence

MIT. Made by [Mofiyinfoluwa Ebo](https://mofiyinebo.com).
