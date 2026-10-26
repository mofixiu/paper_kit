// Short usage examples for every paper_kit widget. kit.mofiyinebo.com shows the
// code between each `#region` and `#endregion`; the analyzer checks all of it.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paper_kit/paper_kit.dart';

// #region theme
class NotebookApp extends StatelessWidget {
  const NotebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final paper = PaperThemeData.light(
      fontBuilder: (style) => GoogleFonts.montserrat(textStyle: style),
    );
    return MaterialApp(
      theme: paper.toMaterialTheme(),
      home: PaperTheme(data: paper, child: const NotebookPage()),
    );
  }
}
// #endregion

// #region background
class NotebookPage extends StatelessWidget {
  const NotebookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: const [PaperHeading('today'), TodayList()],
          ),
        ),
      ),
    );
  }
}
// #endregion

// #region heading
Widget sectionTitles() {
  return const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PaperHeading('Work experience'), // shown as "work experience"
      SizedBox(height: 24),
      PaperHeading('projects', size: 22),
    ],
  );
}
// #endregion

class ThemeSwitch extends StatefulWidget {
  const ThemeSwitch({super.key});

  @override
  State<ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<ThemeSwitch> {
  // #region toggle
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    // Reads "dark" while the page is light, and "light" while it's dark.
    return PaperThemeToggle(
      isDark: _dark,
      onChanged: (dark) => setState(() => _dark = dark),
    );
  }

  // #endregion
}

class InkyApp extends StatefulWidget {
  const InkyApp({super.key});

  @override
  State<InkyApp> createState() => _InkyAppState();
}

class _InkyAppState extends State<InkyApp> {
  // #region reveal
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    final paper = _dark ? PaperThemeData.dark() : PaperThemeData.light();
    return MaterialApp(
      // The new palette spreads over the old one like ink.
      builder: (context, child) => PaperInkReveal(theme: paper, child: child!),
      home: Scaffold(
        body: Center(
          child: PaperThemeToggle(
            isDark: _dark,
            onChanged: (dark) => setState(() => _dark = dark),
          ),
        ),
      ),
    );
  }

  // #endregion
}

// #region stamp
class ApproveInvoice extends StatelessWidget {
  const ApproveInvoice({super.key, required this.onApproved});

  final VoidCallback onApproved;

  @override
  Widget build(BuildContext context) {
    // Every press leaves a red "approved" impression that slowly fades.
    return PaperStampButton(label: 'Approved', onPressed: onApproved);
  }
}
// #endregion

class TodayList extends StatefulWidget {
  const TodayList({super.key});

  @override
  State<TodayList> createState() => _TodayListState();
}

class _TodayListState extends State<TodayList> {
  // #region checkbox
  final _done = {'water the plants': true, 'call mum': false};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final task in _done.keys)
          PaperCheckbox(
            label: task, // crossed out once ticked
            value: _done[task]!,
            onChanged: (value) => setState(() => _done[task] = value),
          ),
      ],
    );
  }

  // #endregion
}

class EmailField extends StatefulWidget {
  const EmailField({super.key});

  @override
  State<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<EmailField> {
  // #region field
  String? _error;

  @override
  Widget build(BuildContext context) {
    return PaperTextField(
      label: 'Email',
      hint: 'you@example.com',
      keyboardType: TextInputType.emailAddress,
      errorText: _error, // a wavy red-pen underline
      onChanged: (text) => setState(() {
        _error = text.contains('@') ? null : 'That needs an @';
      }),
    );
  }

  // #endregion
}

class Sections extends StatefulWidget {
  const Sections({super.key});

  @override
  State<Sections> createState() => _SectionsState();
}

class _SectionsState extends State<Sections> {
  // #region tabs
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    final tone = PaperTheme.of(context).palette;
    return PaperIndexTabs(
      selectedIndex: _open,
      onChanged: (index) => setState(() => _open = index),
      tabs: [
        PaperTab(label: 'today', tone: tone.amber, child: const Text('Plans')),
        PaperTab(
          label: 'thoughts',
          tone: tone.blue,
          child: const Text('Notes'),
        ),
        PaperTab(label: 'week', tone: tone.green, child: const Text('Mon–Sun')),
      ],
    );
  }

  // #endregion
}

class BookingTicket extends StatefulWidget {
  const BookingTicket({super.key});

  @override
  State<BookingTicket> createState() => _BookingTicketState();
}

class _BookingTicketState extends State<BookingTicket> {
  // #region ticket
  final _ticket = GlobalKey<PaperTearToConfirmState>();

  @override
  Widget build(BuildContext context) {
    return PaperTearToConfirm(
      key: _ticket,
      label: 'Admit one · table for two, 8pm',
      stubLabel: 'tear',
      onConfirmed: () => debugPrint('booked'),
    );
  }

  // Puts the stub back and clears the "confirmed" stamp.
  void undo() => _ticket.currentState?.reset();
  // #endregion
}

// #region receipt
Future<void> printReceipt(BuildContext context) {
  // Prints from a slot at the top of the screen, then tears itself off.
  return PaperReceipt.show(
    context,
    title: 'Order #2041',
    lines: const [
      PaperReceiptLine('Jollof rice', '4,500.00'),
      PaperReceiptLine('Chapman', '1,800.00'),
      PaperReceiptLine('Total', '6,300.00'),
    ],
    footer: 'thank you · come again',
  );
}
// #endregion

// #region plane
class SendLetter extends StatelessWidget {
  const SendLetter({super.key, required this.onSent});

  final VoidCallback onSent;

  @override
  Widget build(BuildContext context) {
    // Folds into a paper plane, flies off, then reads "✓ sent".
    return PaperPlaneButton(label: 'send', sentLabel: 'sent', onSent: onSent);
  }
}
// #endregion

// #region peel
class Reminder extends StatelessWidget {
  const Reminder({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    // Drag the curled corner past halfway and the note comes off.
    return PaperPeel(
      size: 180,
      onPeeled: onDone,
      child: const Text('Buy stamps\nPost the zine\nCall Tobi'),
    );
  }
}
// #endregion

// #region zine
Widget foldingGuide() {
  return const PaperZine(
    title: 'How to fold a zine',
    panelHeight: 72,
    panels: [
      Text('1 · Fold the sheet in half, long edge to long edge.'),
      Text('2 · Fold it in half again, then once more.'),
      Text('3 · Cut along the middle fold, between the inner panels.'),
      Text('4 · Push the ends together and flatten it into a booklet.'),
    ],
  );
}
// #endregion

// #region note
Widget pinnedNote(BuildContext context) {
  return PaperNote(
    rotation: -0.03, // straightens up on hover
    tape: PaperTheme.of(context).palette.teal,
    child: const SizedBox(
      width: 220,
      child: Text('Ship the CV and the kit this week.'),
    ),
  );
}
// #endregion

class SleepRuler extends StatefulWidget {
  const SleepRuler({super.key});

  @override
  State<SleepRuler> createState() => _SleepRulerState();
}

class _SleepRulerState extends State<SleepRuler> {
  // #region ruler
  double _hours = 7.5;

  @override
  Widget build(BuildContext context) {
    return PaperRuler(
      value: _hours,
      min: 4,
      max: 12,
      divisions: 16, // a mark every half hour
      label: (hours) => '${hours.toStringAsFixed(1)}h',
      onChanged: (hours) => setState(() => _hours = hours),
    );
  }

  // #endregion
}

class PhoneDemoSnippet extends StatefulWidget {
  const PhoneDemoSnippet({super.key});

  @override
  State<PhoneDemoSnippet> createState() => _PhoneDemoSnippetState();
}

class _PhoneDemoSnippetState extends State<PhoneDemoSnippet> {
  // #region phone
  final _fingertip = PaperDemoController();
  final _stamp = GlobalKey();

  // Call _demo.play() in initState. A real touch on the screen stops it.
  late final _demo = PaperDemoScript(
    controller: _fingertip,
    steps: [PaperDemoStep.tapKey(_stamp)], // taps the real button
  );

  @override
  Widget build(BuildContext context) {
    return PaperPhoneFrame(
      width: 280,
      demo: _fingertip,
      child: PaperBackground(
        child: Center(
          child: PaperStampButton(
            key: _stamp,
            label: 'filed',
            onPressed: () {},
          ),
        ),
      ),
    );
  }
  // #endregion

  @override
  void initState() {
    super.initState();
    _demo.play();
  }

  @override
  void dispose() {
    _fingertip.dispose();
    super.dispose();
  }
}
