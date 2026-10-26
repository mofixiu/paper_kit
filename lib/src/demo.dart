import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'motion.dart';

/// The `device` id on pointer events sent by a [PaperDemoController], so they can be
/// told apart from real touches.
const int kPaperDemoPointerDevice = 0x70A9E7;

/// Drives a [PaperFingertip]: a fake fingertip that glides over a screen and taps
/// and drags the real widgets under it.
///
/// Positions are fractions of the fingertip's area: (0, 0) is the top-left corner
/// and (1, 1) the bottom-right. Any real touch on a [PaperPhoneFrame] calls
/// [interrupt], which stops a running [PaperDemoScript].
class PaperDemoController extends ChangeNotifier {
  Offset _position = const Offset(0.5, 1.05);
  bool _visible = false;
  bool _pressing = false;
  bool _holding = false;
  int _ripples = 0;
  int _generation = 0;
  _PaperFingertipState? _host;
  final Set<_Sleep> _sleeps = {};

  /// Where the fingertip is, as a fraction of its area.
  Offset get position => _position;

  /// Whether the fingertip is showing.
  bool get visible => _visible;

  /// Whether the fingertip is pressed against the screen.
  bool get pressing => _pressing || _holding;

  /// Counts presses; each one sends out a ripple.
  int get ripples => _ripples;

  /// Goes up by one every time [interrupt] is called.
  int get generation => _generation;

  /// Glides the fingertip to [target].
  Future<void> moveTo(
    Offset target, {
    Duration duration = const Duration(milliseconds: 650),
  }) {
    _visible = true;
    notifyListeners();
    final host = _host;
    if (host == null) {
      _position = target;
      notifyListeners();
      return Future<void>.value();
    }
    return host._glideTo(target, duration);
  }

  /// Glides the fingertip onto the widget with [key].
  Future<void> moveToKey(
    GlobalKey key, {
    Alignment alignment = Alignment.center,
    Duration duration = const Duration(milliseconds: 650),
  }) {
    final target = _host?._fractionOf(key, alignment);
    if (target == null) return Future<void>.value();
    return moveTo(target, duration: duration);
  }

  /// Presses and lifts the fingertip. With [tap], the widget underneath is tapped
  /// for real.
  Future<void> press({bool tap = true}) async {
    _visible = true;
    _pressing = true;
    _ripples++;
    notifyListeners();
    final pointer = tap ? _host?._down() : null;
    await wait(const Duration(milliseconds: 170));
    _pressing = false;
    notifyListeners();
    if (pointer != null) _host?._up(pointer);
  }

  /// Presses, drags by [by] logical pixels and lifts, moving whatever is underneath.
  Future<void> drag(
    Offset by, {
    Duration duration = const Duration(milliseconds: 700),
  }) async {
    final host = _host;
    if (host == null) return;
    _visible = true;
    _holding = true;
    _ripples++;
    notifyListeners();
    final pointer = host._down();
    await wait(const Duration(milliseconds: 120));
    await host._glideTo(host._fractionBy(by), duration, dragging: pointer);
    if (pointer != null) host._up(pointer);
    _holding = false;
    notifyListeners();
  }

  /// Hides the fingertip.
  void hide() {
    _visible = false;
    notifyListeners();
  }

  /// Waits for [duration], or less if [interrupt] is called.
  Future<void> wait(Duration duration) {
    final sleep = _Sleep();
    _sleeps.add(sleep);
    sleep.timer = Timer(duration, () {
      _sleeps.remove(sleep);
      sleep.wake();
    });
    return sleep.completer.future;
  }

  /// Stops whatever the fingertip is doing and hides it.
  void interrupt() {
    _generation++;
    for (final sleep in _sleeps.toList()) {
      sleep.timer?.cancel();
      sleep.wake();
    }
    _sleeps.clear();
    _pressing = false;
    _holding = false;
    _host?._stop();
    hide();
  }

  @override
  void dispose() {
    interrupt();
    super.dispose();
  }
}

class _Sleep {
  final completer = Completer<void>();
  Timer? timer;

  void wake() {
    if (!completer.isCompleted) completer.complete();
  }
}

/// One thing a [PaperDemoScript] does.
class PaperDemoStep {
  PaperDemoStep._(this._run);

  /// Glides to [at].
  factory PaperDemoStep.moveTo(
    Offset at, {
    Duration duration = const Duration(milliseconds: 650),
  }) =>
      PaperDemoStep._((c) => c.moveTo(at, duration: duration));

  /// Glides to [at] and taps.
  factory PaperDemoStep.tap(Offset at) => PaperDemoStep._((c) async {
        await c.moveTo(at);
        await c.press();
      });

  /// Glides onto the widget with [key] and taps it.
  factory PaperDemoStep.tapKey(
    GlobalKey key, {
    Alignment alignment = Alignment.center,
  }) =>
      PaperDemoStep._((c) async {
        await c.moveToKey(key, alignment: alignment);
        await c.press();
      });

  /// Presses where the fingertip is and drags by [by] logical pixels.
  factory PaperDemoStep.drag(
    Offset by, {
    Duration duration = const Duration(milliseconds: 700),
  }) =>
      PaperDemoStep._((c) => c.drag(by, duration: duration));

  /// Glides onto the widget with [key], then drags it by [by] logical pixels.
  factory PaperDemoStep.dragKey(
    GlobalKey key,
    Offset by, {
    Alignment alignment = Alignment.center,
    Duration duration = const Duration(milliseconds: 700),
  }) =>
      PaperDemoStep._((c) async {
        await c.moveToKey(key, alignment: alignment);
        await c.drag(by, duration: duration);
      });

  /// Waits.
  factory PaperDemoStep.wait(Duration duration) =>
      PaperDemoStep._((c) => c.wait(duration));

  /// Runs [action], for example to reset the screen between loops.
  factory PaperDemoStep.run(FutureOr<void> Function() action) =>
      PaperDemoStep._((c) async => action());

  /// Hides the fingertip.
  factory PaperDemoStep.hide() => PaperDemoStep._((c) async => c.hide());

  final Future<void> Function(PaperDemoController controller) _run;
}

/// Plays [steps] with a [PaperDemoController], pausing between them, and loops.
///
/// It stops by itself as soon as someone touches the screen.
class PaperDemoScript {
  /// A script for [controller].
  PaperDemoScript({
    required this.controller,
    required this.steps,
    this.loop = true,
    this.pause = const Duration(milliseconds: 900),
    this.startDelay = const Duration(milliseconds: 700),
    this.loopDelay = const Duration(milliseconds: 1800),
    this.onLoop,
  });

  /// The fingertip to drive.
  final PaperDemoController controller;

  /// What to do, in order.
  final List<PaperDemoStep> steps;

  /// Whether to start again from the top after the last step.
  final bool loop;

  /// The rest after each step.
  final Duration pause;

  /// The wait before the first step.
  final Duration startDelay;

  /// The wait before starting again.
  final Duration loopDelay;

  /// Called after each run through the steps, before the next.
  final VoidCallback? onLoop;

  int? _token;

  /// Whether the script is running.
  bool get isPlaying => _token != null && controller.generation == _token;

  /// Starts from the first step. Completes when the script stops.
  Future<void> play() async {
    controller.interrupt();
    final token = _token = controller.generation;
    bool alive() => controller.generation == token;
    await controller.wait(startDelay);
    do {
      for (final step in steps) {
        if (!alive()) return;
        await step._run(controller);
        if (!alive()) return;
        await controller.wait(pause);
      }
      if (!alive()) return;
      controller.hide();
      onLoop?.call();
      await controller.wait(loopDelay);
    } while (loop && alive());
    if (alive()) _token = null;
  }

  /// Stops the script and hides the fingertip.
  void stop() => controller.interrupt();
}

/// The fake fingertip a [PaperDemoController] moves. Place it over the screen it
/// should tap, filling it; [PaperPhoneFrame] does this when given a controller.
class PaperFingertip extends StatefulWidget {
  /// A fingertip driven by [controller].
  const PaperFingertip({super.key, required this.controller});

  /// Moves and presses the fingertip.
  final PaperDemoController controller;

  @override
  State<PaperFingertip> createState() => _PaperFingertipState();
}

class _PaperFingertipState extends State<PaperFingertip>
    with TickerProviderStateMixin {
  static int _nextPointer = 0x7A0000;

  late final AnimationController _glide;
  late final AnimationController _ripple;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  int? _dragging;
  int? _activePointer;
  Offset? _lastGlobal;
  int _seenRipples = 0;

  @override
  void initState() {
    super.initState();
    _glide = AnimationController(vsync: this)..addListener(_onGlide);
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(PaperFingertip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detach(oldWidget.controller);
      _attach(widget.controller);
    }
  }

  void _attach(PaperDemoController controller) {
    controller._host = this;
    controller.addListener(_onController);
    _seenRipples = controller.ripples;
  }

  void _detach(PaperDemoController controller) {
    controller.removeListener(_onController);
    if (controller._host == this) controller._host = null;
  }

  @override
  void dispose() {
    _cancelPointer();
    _detach(widget.controller);
    _glide.dispose();
    _ripple.dispose();
    super.dispose();
  }

  void _onController() {
    if (widget.controller.ripples != _seenRipples) {
      _seenRipples = widget.controller.ripples;
      _ripple.forward(from: 0);
    }
    setState(() {});
  }

  Future<void> _glideTo(Offset to, Duration duration, {int? dragging}) {
    _from = widget.controller._position;
    _to = to;
    _dragging = dragging;
    _glide.duration = duration;
    final done = Completer<void>();
    _glide.forward(from: 0).whenCompleteOrCancel(() {
      _dragging = null;
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  void _onGlide() {
    final t = PaperMotion.fingertip.transform(_glide.value);
    widget.controller._position = Offset.lerp(_from, _to, t)!;
    final pointer = _dragging;
    if (pointer != null) _move(pointer);
    setState(() {});
  }

  void _stop() {
    _glide.stop();
    _cancelPointer();
  }

  RenderBox? get _box {
    final object = context.findRenderObject();
    return object is RenderBox && object.hasSize && object.attached
        ? object
        : null;
  }

  Offset? _fractionOf(GlobalKey key, Alignment alignment) {
    final box = _box;
    final target = key.currentContext?.findRenderObject();
    if (box == null || target is! RenderBox || !target.attached) return null;
    final global = target.localToGlobal(alignment.alongSize(target.size));
    final local = box.globalToLocal(global);
    return Offset(local.dx / box.size.width, local.dy / box.size.height);
  }

  Offset _fractionBy(Offset by) {
    final box = _box;
    final position = widget.controller._position;
    if (box == null) return position;
    return position + Offset(by.dx / box.size.width, by.dy / box.size.height);
  }

  Offset? _global() {
    final box = _box;
    if (box == null) return null;
    final position = widget.controller._position;
    return box.localToGlobal(
      Offset(position.dx * box.size.width, position.dy * box.size.height),
    );
  }

  Duration get _now => SchedulerBinding.instance.currentSystemFrameTimeStamp;

  int? _down() {
    final global = _global();
    if (global == null) return null;
    _cancelPointer();
    final pointer = _nextPointer++;
    _activePointer = pointer;
    _lastGlobal = global;
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        timeStamp: _now,
        pointer: pointer,
        device: kPaperDemoPointerDevice,
        position: global,
      ),
    );
    return pointer;
  }

  void _move(int pointer) {
    final global = _global();
    if (global == null || pointer != _activePointer) return;
    final delta = global - (_lastGlobal ?? global);
    _lastGlobal = global;
    if (delta == Offset.zero) return;
    GestureBinding.instance.handlePointerEvent(
      PointerMoveEvent(
        timeStamp: _now,
        pointer: pointer,
        device: kPaperDemoPointerDevice,
        position: global,
        delta: delta,
      ),
    );
  }

  void _up(int pointer) {
    if (pointer != _activePointer) return;
    _activePointer = null;
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(
        timeStamp: _now,
        pointer: pointer,
        device: kPaperDemoPointerDevice,
        position: _lastGlobal ?? _global() ?? Offset.zero,
      ),
    );
  }

  void _cancelPointer() {
    final pointer = _activePointer;
    if (pointer == null) return;
    _activePointer = null;
    GestureBinding.instance.handlePointerEvent(
      PointerCancelEvent(
        timeStamp: _now,
        pointer: pointer,
        device: kPaperDemoPointerDevice,
        position: _lastGlobal ?? Offset.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final diameter = width * 0.11;
          final centre = Offset(
            controller.position.dx * width,
            controller.position.dy * height,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: centre.dx - diameter / 2,
                top: centre.dy - diameter / 2,
                width: diameter,
                height: diameter,
                child: AnimatedOpacity(
                  opacity: controller.visible ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: AnimatedScale(
                    scale: controller.pressing ? 0.82 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedBuilder(
                      animation: _ripple,
                      builder: (context, _) => CustomPaint(
                        painter: _FingertipPainter(
                          pressing: controller.pressing,
                          ripple: _ripple.isAnimating ? _ripple.value : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FingertipPainter extends CustomPainter {
  const _FingertipPainter({required this.pressing, required this.ripple});

  final bool pressing;
  final double? ripple;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas
      ..drawCircle(
        centre + const Offset(0, 4),
        radius + 1,
        Paint()
          ..color = const Color(0x59000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      )
      ..drawCircle(
        centre,
        radius,
        Paint()
          ..color =
              pressing ? const Color(0x8CFFFFFF) : const Color(0x47141414),
      )
      ..drawCircle(
        centre,
        radius - 1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xF2FFFFFF),
      );
    final r = ripple;
    if (r != null) {
      final eased = Curves.easeOut.transform(r);
      canvas.drawCircle(
        centre,
        (radius + 1) * (1 + 1.2 * eased),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * (1 - r)),
      );
    }
  }

  @override
  bool shouldRepaint(_FingertipPainter oldDelegate) =>
      oldDelegate.pressing != pressing || oldDelegate.ripple != ripple;
}
