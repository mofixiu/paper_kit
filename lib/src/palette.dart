import 'package:flutter/widgets.dart';

/// The inks and papers of the kit, in a light (cream) and a dark (espresso) set.
@immutable
class PaperPalette {
  /// Creates a palette. Most apps use [PaperPalette.light] or [PaperPalette.dark].
  const PaperPalette({
    required this.brightness,
    required this.paper,
    required this.sheet,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.rule,
    required this.accent,
    required this.primary,
    required this.onPrimary,
    required this.redPen,
    required this.blueInk,
    required this.note,
    required this.amber,
    required this.blue,
    required this.red,
    required this.green,
    required this.plum,
    required this.rust,
    required this.teal,
    required this.tabInk,
  });

  /// Cream paper and dark ink.
  static const PaperPalette light = PaperPalette(
    brightness: Brightness.light,
    paper: Color(0xFFF4ECDE),
    sheet: Color(0xFFFBF7EF),
    ink: Color(0xFF211E19),
    muted: Color(0xFF6B6256),
    faint: Color(0xFF9D9386),
    rule: Color(0xFFD8CEBC),
    accent: Color(0xFF8E7D67),
    primary: Color(0xFF322D26),
    onPrimary: Color(0xFFF4ECDE),
    redPen: Color(0xFFB8432F),
    blueInk: Color(0xFF3F5D7D),
    note: Color(0xFFF3E3B5),
    amber: Color(0xFFB37B26),
    blue: Color(0xFF3F5D7D),
    red: Color(0xFFB8432F),
    green: Color(0xFF567849),
    plum: Color(0xFF7A4B6B),
    rust: Color(0xFF93522A),
    teal: Color(0xFF2B6E69),
    tabInk: Color(0xFFFFF8EE),
  );

  /// Espresso paper and pale ink.
  static const PaperPalette dark = PaperPalette(
    brightness: Brightness.dark,
    paper: Color(0xFF171512),
    sheet: Color(0xFF211F1B),
    ink: Color(0xFFF8F3EA),
    muted: Color(0xFFB9B0A2),
    faint: Color(0xFF81786C),
    rule: Color(0xFF4B463E),
    accent: Color(0xFFC9BDA7),
    primary: Color(0xFFF3EADB),
    onPrimary: Color(0xFF171512),
    redPen: Color(0xFFE0715C),
    blueInk: Color(0xFF8FB0D6),
    note: Color(0xFF4A4130),
    amber: Color(0xFFD9A54B),
    blue: Color(0xFF87A7CD),
    red: Color(0xFFE0715C),
    green: Color(0xFF93B683),
    plum: Color(0xFFBE92B1),
    rust: Color(0xFFD58D59),
    teal: Color(0xFF6DB5AE),
    tabInk: Color(0xFF17140F),
  );

  /// Returns [light] or [dark].
  static PaperPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Whether this is the light or the dark set.
  final Brightness brightness;

  /// The page itself.
  final Color paper;

  /// A raised sheet lying on the page: cards, tickets, receipts.
  final Color sheet;

  /// Body text and outlines.
  final Color ink;

  /// Secondary text.
  final Color muted;

  /// Hints and disabled text.
  final Color faint;

  /// Hairlines and borders.
  final Color rule;

  /// A warm brown for small highlights.
  final Color accent;

  /// Filled controls.
  final Color primary;

  /// Text and icons on [primary].
  final Color onPrimary;

  /// Corrections, errors and stamp impressions.
  final Color redPen;

  /// Ticks and links.
  final Color blueInk;

  /// Sticky notes.
  final Color note;

  /// Index-tab tone.
  final Color amber;

  /// Index-tab tone.
  final Color blue;

  /// Index-tab tone.
  final Color red;

  /// Index-tab tone.
  final Color green;

  /// Index-tab tone.
  final Color plum;

  /// Index-tab tone.
  final Color rust;

  /// Index-tab tone.
  final Color teal;

  /// Text on the index-tab tones.
  final Color tabInk;

  /// The index-tab tones, in order.
  List<Color> get tones => [amber, blue, red, green, plum, rust, teal];

  /// Whether this is the dark set.
  bool get isDark => brightness == Brightness.dark;

  /// A copy with some colours replaced.
  PaperPalette copyWith({
    Color? paper,
    Color? sheet,
    Color? ink,
    Color? muted,
    Color? faint,
    Color? rule,
    Color? accent,
    Color? primary,
    Color? onPrimary,
    Color? redPen,
    Color? blueInk,
    Color? note,
    Color? tabInk,
  }) {
    return PaperPalette(
      brightness: brightness,
      paper: paper ?? this.paper,
      sheet: sheet ?? this.sheet,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      rule: rule ?? this.rule,
      accent: accent ?? this.accent,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      redPen: redPen ?? this.redPen,
      blueInk: blueInk ?? this.blueInk,
      note: note ?? this.note,
      amber: amber,
      blue: blue,
      red: red,
      green: green,
      plum: plum,
      rust: rust,
      teal: teal,
      tabInk: tabInk ?? this.tabInk,
    );
  }

  List<Object> get _props => [
        brightness,
        paper,
        sheet,
        ink,
        muted,
        faint,
        rule,
        accent,
        primary,
        onPrimary,
        redPen,
        blueInk,
        note,
        amber,
        blue,
        red,
        green,
        plum,
        rust,
        teal,
        tabInk,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PaperPalette) return false;
    final a = _props;
    final b = other._props;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_props);
}
