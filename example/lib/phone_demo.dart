import 'package:flutter/material.dart';
import 'package:paper_kit/paper_kit.dart';

/// A phone running a tiny to-do app, with a fingertip that taps through it by
/// itself: ticks two boxes, stamps the page and tears off a ticket.
class PhoneDemo extends StatefulWidget {
  const PhoneDemo({super.key, this.autoplay = true, this.width = 280});

  final bool autoplay;
  final double width;

  @override
  State<PhoneDemo> createState() => _PhoneDemoState();
}

class _PhoneDemoState extends State<PhoneDemo> {
  final _fingertip = PaperDemoController();
  final _plants = GlobalKey();
  final _zine = GlobalKey();
  final _stamp = GlobalKey();
  final _ticket = GlobalKey<PaperTearToConfirmState>();
  bool _watered = false;
  bool _posted = false;
  int _filed = 0;

  late final _script = PaperDemoScript(
    controller: _fingertip,
    steps: [
      PaperDemoStep.tapKey(_plants),
      PaperDemoStep.tapKey(_zine),
      PaperDemoStep.tapKey(_stamp),
      PaperDemoStep.dragKey(
        _ticket,
        const Offset(120, 6),
        alignment: const Alignment(0.72, 0),
      ),
      PaperDemoStep.wait(const Duration(milliseconds: 1400)),
    ],
    onLoop: _reset,
  );

  @override
  void initState() {
    super.initState();
    if (widget.autoplay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _script.play());
    }
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _watered = false;
      _posted = false;
    });
    _ticket.currentState?.reset();
  }

  void _replay() {
    _reset();
    _script.play();
  }

  @override
  void dispose() {
    _fingertip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaperTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PaperPhoneFrame(
          width: widget.width,
          demo: _fingertip,
          statusBar: theme.isDark
              ? PaperStatusBarStyle.light
              : PaperStatusBarStyle.dark,
          child: PaperBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PaperHeading('today', size: 24),
                    const SizedBox(height: 18),
                    PaperCheckbox(
                      key: _plants,
                      label: 'water the plants',
                      value: _watered,
                      onChanged: (v) => setState(() => _watered = v),
                    ),
                    PaperCheckbox(
                      key: _zine,
                      label: 'post the zine',
                      value: _posted,
                      onChanged: (v) => setState(() => _posted = v),
                    ),
                    const SizedBox(height: 22),
                    PaperStampButton(
                      key: _stamp,
                      label: 'filed',
                      onPressed: () => setState(() => _filed++),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _filed == 1 ? 'filed once' : 'filed $_filed times',
                      style: theme.text(size: 12, color: theme.palette.muted),
                    ),
                    const Spacer(),
                    PaperTearToConfirm(
                      key: _ticket,
                      label: 'lunch with tobi · 12:30',
                      height: 82,
                      onConfirmed: () {},
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: _replay,
          child: Text(
            'replay demo',
            style: theme
                .text(size: 13, weight: FontWeight.w700)
                .copyWith(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }
}
