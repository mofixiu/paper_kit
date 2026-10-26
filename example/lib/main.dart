import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paper_kit/paper_kit.dart';

import 'phone_demo.dart';

TextStyle montserrat(TextStyle style) =>
    GoogleFonts.montserrat(textStyle: style);

void main() => runApp(const PaperKitGallery(fontBuilder: montserrat));

/// Every paper_kit widget on one page of paper.
class PaperKitGallery extends StatefulWidget {
  const PaperKitGallery({
    super.key,
    this.fontBuilder,
    this.fontFamily = 'Montserrat',
    this.initiallyDark = false,
    this.autoplay = true,
  });

  final PaperFontBuilder? fontBuilder;
  final String fontFamily;
  final bool initiallyDark;

  /// Whether the phone demo plays by itself.
  final bool autoplay;

  @override
  State<PaperKitGallery> createState() => _PaperKitGalleryState();
}

class _PaperKitGalleryState extends State<PaperKitGallery> {
  late bool _dark = widget.initiallyDark;
  Offset? _origin;
  final _toggle = GlobalKey();

  void _setDark(bool dark) {
    final box = _toggle.currentContext?.findRenderObject() as RenderBox?;
    setState(() {
      _origin = box?.localToGlobal(box.size.center(Offset.zero));
      _dark = dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperThemeData.fromBrightness(
      _dark ? Brightness.dark : Brightness.light,
      fontFamily: widget.fontFamily,
      fontBuilder: widget.fontBuilder,
    );
    return MaterialApp(
      title: 'paper kit',
      debugShowCheckedModeBanner: false,
      theme: theme.toMaterialTheme(),
      builder: (context, child) =>
          PaperInkReveal(theme: theme, origin: _origin, child: child!),
      home: GalleryPage(
        isDark: _dark,
        onDarkChanged: _setDark,
        toggleKey: _toggle,
        autoplay: widget.autoplay,
      ),
    );
  }
}

class GalleryPage extends StatelessWidget {
  const GalleryPage({
    super.key,
    required this.isDark,
    required this.onDarkChanged,
    required this.toggleKey,
    required this.autoplay,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;
  final Key toggleKey;
  final bool autoplay;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final muted = theme.text(size: 14, color: theme.palette.muted, height: 1.5);
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 48),
                children: [
                  Row(
                    children: [
                      Text(
                        'paper kit',
                        style: theme.text(
                          size: 18,
                          weight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('0.1.0', style: muted),
                      const Spacer(),
                      PaperThemeToggle(
                        key: toggleKey,
                        isDark: isDark,
                        onChanged: onDarkChanged,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const PaperHeading('ink on paper', size: 34),
                  const SizedBox(height: 18),
                  Text(
                    'A handmade-paper UI kit for Flutter. Everything on this '
                    'page is a live widget: stamp it, tick it, tear it, peel it.',
                    style: muted,
                  ),
                  const SizedBox(height: 22),
                  const _Swatches(),
                  const _Section(title: 'stamps', child: _StampDemo()),
                  const _Section(title: 'checkboxes', child: _TodoDemo()),
                  const _Section(title: 'fields', child: _FieldDemo()),
                  const _Section(title: 'index tabs', child: _TabsDemo()),
                  const _Section(
                    title: 'tear to confirm',
                    child: _TicketDemo(),
                  ),
                  _Section(
                    title: 'receipts',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PaperStampButton(
                        label: 'print receipt',
                        onPressed: () => PaperReceipt.show(
                          context,
                          title: 'order #2041',
                          lines: const [
                            PaperReceiptLine('jollof rice', '4,500.00'),
                            PaperReceiptLine('chapman', '1,800.00'),
                            PaperReceiptLine('total', '6,300.00'),
                          ],
                          footer: 'thank you · come again',
                        ),
                      ),
                    ),
                  ),
                  const _Section(title: 'paper plane', child: _PlaneDemo()),
                  const _Section(title: 'sticky notes', child: _PeelDemo()),
                  const _Section(
                    title: 'zine',
                    child: PaperZine(
                      title: 'how to fold a zine',
                      panels: [
                        Text(
                          '1 · fold the sheet in half, long edge to long edge',
                        ),
                        Text('2 · fold it in half again, then once more'),
                        Text(
                          '3 · cut along the middle fold, between the inner panels',
                        ),
                        Text(
                          '4 · push the ends together and flatten it into a booklet',
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'notes',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PaperNote(
                        tape: theme.palette.teal,
                        child: const SizedBox(
                          width: 240,
                          child: Text(
                            'Taped to the page, a little crooked. Hover and it '
                            'straightens up.',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const _Section(title: 'ruler', child: _RulerDemo()),
                  const _Section(
                    title: 'envelope',
                    child: Center(
                      child: PaperEnvelope(
                        to: 'for tobi',
                        letter: Text('the zine swap is on saturday at 3pm.'),
                      ),
                    ),
                  ),
                  const _Section(
                    title: 'typewriter',
                    child: PaperTypewriter(
                      'dear tobi,\nbring something you made.',
                      autostart: false,
                    ),
                  ),
                  const _Section(
                    title: 'flip pad',
                    child: Center(
                      child: PaperFlipPad(
                        pages: [
                          Text('monday\nscan the film'),
                          Text('wednesday\nlay out the zine'),
                          Text('friday\nprint run'),
                        ],
                      ),
                    ),
                  ),
                  const _Section(title: 'shredder', child: _ShredderDemo()),
                  _Section(
                    title: 'marking up',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PaperHighlightSwitch(
                          label: 'remind me on friday',
                          value: true,
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 16),
                        const PaperRedact(
                          'the spare key is under the third plant pot.',
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'punch card',
                    child: Center(
                      child: PaperPunchCard(
                        title: 'coffee',
                        holes: 10,
                        punched: 3,
                        onPunch: (_) {},
                      ),
                    ),
                  ),
                  _Section(
                    title: 'paperclip',
                    child: Center(
                      child: PaperClip(
                        attachment: const _Slip(
                          Text('receipt\n£12.40'),
                          padding: EdgeInsets.fromLTRB(40, 14, 16, 14),
                        ),
                        child: _Slip(
                          const Text('october expenses'),
                          width: 280,
                          height: 150,
                          padding: const EdgeInsets.fromLTRB(130, 20, 20, 20),
                        ),
                      ),
                    ),
                  ),
                  const _Section(
                    title: 'cut here',
                    child: PaperCutRule(
                      child: _Slip(Text('20% off your next print run')),
                    ),
                  ),
                  _Section(
                    title: 'phone frame',
                    child: Center(child: PhoneDemo(autoplay: autoplay)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: PaperHeading(title, size: 22),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    final swatches = {
      'paper': p.paper,
      'sheet': p.sheet,
      'ink': p.ink,
      'muted': p.muted,
      'red pen': p.redPen,
      'blue ink': p.blueInk,
      'note': p.note,
    };
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final entry in swatches.entries)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 40,
                decoration: BoxDecoration(
                  color: entry.value,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: p.rule),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.key,
                style: theme.text(
                  size: 10,
                  weight: FontWeight.w600,
                  color: p.muted,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _StampDemo extends StatefulWidget {
  const _StampDemo();

  @override
  State<_StampDemo> createState() => _StampDemoState();
}

class _StampDemoState extends State<_StampDemo> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    return Row(
      children: [
        PaperStampButton(
          label: 'approved',
          onPressed: () => setState(() => _count++),
        ),
        const SizedBox(width: 24),
        Text(
          _count == 0 ? 'press it' : 'stamped $_count',
          style: theme.text(size: 13, color: theme.palette.muted),
        ),
      ],
    );
  }
}

class _TodoDemo extends StatefulWidget {
  const _TodoDemo();

  @override
  State<_TodoDemo> createState() => _TodoDemoState();
}

class _TodoDemoState extends State<_TodoDemo> {
  final _done = {
    'water the plants': true,
    'call mum': false,
    'write the release notes': false,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final task in _done.keys)
          PaperCheckbox(
            label: task,
            value: _done[task]!,
            onChanged: (value) => setState(() => _done[task] = value),
          ),
      ],
    );
  }
}

class _FieldDemo extends StatefulWidget {
  const _FieldDemo();

  @override
  State<_FieldDemo> createState() => _FieldDemoState();
}

class _FieldDemoState extends State<_FieldDemo> {
  final _email = TextEditingController(text: 'ada@');
  String? _error = 'that needs a full address';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PaperTextField(label: 'name', hint: 'Ada Lovelace'),
        const SizedBox(height: 22),
        PaperTextField(
          label: 'email',
          controller: _email,
          errorText: _error,
          onChanged: (text) => setState(() {
            _error = RegExp(r'^\S+@\S+\.\S+$').hasMatch(text)
                ? null
                : 'that needs a full address';
          }),
        ),
      ],
    );
  }
}

class _TabsDemo extends StatefulWidget {
  const _TabsDemo();

  @override
  State<_TabsDemo> createState() => _TabsDemoState();
}

class _TabsDemoState extends State<_TabsDemo> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    final p = theme.palette;
    Widget page(String title, String body) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PaperHeading(title, size: 20),
        const SizedBox(height: 16),
        Text(body, style: theme.text(size: 14, height: 1.6)),
      ],
    );
    return PaperIndexTabs(
      selectedIndex: _open,
      onChanged: (index) => setState(() => _open = index),
      tabs: [
        PaperTab(
          label: 'today',
          tone: p.amber,
          child: page('today', 'Three things to do, one thought to keep.'),
        ),
        PaperTab(
          label: 'thoughts',
          tone: p.blue,
          child: page('thoughts', 'A blank page that saves as you write.'),
        ),
        PaperTab(
          label: 'to-do',
          tone: p.red,
          child: page('to-do', 'Call mum on Friday. Post the zine.'),
        ),
        PaperTab(
          label: 'week',
          tone: p.green,
          child: page('week', 'Seven days on one spread.'),
        ),
      ],
    );
  }
}

class _TicketDemo extends StatefulWidget {
  const _TicketDemo();

  @override
  State<_TicketDemo> createState() => _TicketDemoState();
}

class _TicketDemoState extends State<_TicketDemo> {
  final _ticket = GlobalKey<PaperTearToConfirmState>();
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PaperTearToConfirm(
          key: _ticket,
          label: 'admit one · table for two, 8pm',
          onConfirmed: () => setState(() => _confirmed = true),
          onReset: () => setState(() => _confirmed = false),
        ),
        const SizedBox(height: 12),
        if (_confirmed)
          TextButton(
            onPressed: () => _ticket.currentState?.reset(),
            child: Text(
              'put the stub back',
              style: theme.text(size: 13, weight: FontWeight.w700),
            ),
          )
        else
          Text(
            'drag the stub to the right',
            style: theme.text(size: 13, color: theme.palette.muted),
          ),
      ],
    );
  }
}

class _PlaneDemo extends StatefulWidget {
  const _PlaneDemo();

  @override
  State<_PlaneDemo> createState() => _PlaneDemoState();
}

class _PlaneDemoState extends State<_PlaneDemo> {
  int _sent = 0;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    return Row(
      children: [
        PaperPlaneButton(onSent: () => setState(() => _sent++)),
        const SizedBox(width: 24),
        Text(
          _sent == 0 ? 'one letter waiting' : '$_sent sent',
          style: theme.text(size: 13, color: theme.palette.muted),
        ),
      ],
    );
  }
}

class _PeelDemo extends StatefulWidget {
  const _PeelDemo();

  @override
  State<_PeelDemo> createState() => _PeelDemoState();
}

class _PeelDemoState extends State<_PeelDemo> {
  static const _notes = [
    'buy stamps\npost the zine\ncall tobi',
    'dentist, thursday 10am',
    'remember to drink water',
  ];
  int _top = 0;

  @override
  Widget build(BuildContext context) {
    final p = PaperTheme.of(context).palette;
    final colors = [
      p.note,
      Color.lerp(p.note, p.teal, 0.25)!,
      Color.lerp(p.note, p.red, 0.18)!,
    ];
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 8,
            child: PaperPeel(
              key: ValueKey(_top + 1),
              color: colors[(_top + 1) % colors.length],
              child: Text(_notes[(_top + 1) % _notes.length]),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: PaperPeel(
              key: ValueKey(_top),
              color: colors[_top % colors.length],
              onPeeled: () => setState(() => _top++),
              child: Text(_notes[_top % _notes.length]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RulerDemo extends StatefulWidget {
  const _RulerDemo();

  @override
  State<_RulerDemo> createState() => _RulerDemoState();
}

class _RulerDemoState extends State<_RulerDemo> {
  double _hours = 7.5;

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PaperRuler(
          value: _hours,
          min: 4,
          max: 12,
          divisions: 16,
          onChanged: (hours) => setState(() => _hours = hours),
        ),
        const SizedBox(height: 10),
        Text(
          'sleep: $_hours hours',
          style: theme.text(size: 13, color: theme.palette.muted),
        ),
      ],
    );
  }
}

class _ShredderDemo extends StatefulWidget {
  const _ShredderDemo();

  @override
  State<_ShredderDemo> createState() => _ShredderDemoState();
}

class _ShredderDemoState extends State<_ShredderDemo> {
  final _shredder = GlobalKey<PaperShredderState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PaperShredder(
          key: _shredder,
          child: const SizedBox(
            width: 240,
            child: PaperNote(child: Text('first draft, do not read')),
          ),
        ),
        const SizedBox(height: 120),
        PaperStampButton(
          label: 'shred',
          onPressed: () {
            final shredder = _shredder.currentState!;
            shredder.isShredded ? shredder.reset() : shredder.shred();
          },
        ),
      ],
    );
  }
}

class _Slip extends StatelessWidget {
  const _Slip(
    this.child, {
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: PaperTheme.of(context).palette.sheet,
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
}
