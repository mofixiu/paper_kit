import 'package:flutter/material.dart';

import 'palette.dart';

/// Turns a plain [TextStyle] into one that uses a particular font, for example
/// `(style) => GoogleFonts.montserrat(textStyle: style)`.
typedef PaperFontBuilder = TextStyle Function(TextStyle style);

/// Colours and type for the kit's widgets. Provide it with [PaperTheme].
@immutable
class PaperThemeData {
  /// Creates theme data from a palette.
  const PaperThemeData({
    required this.palette,
    this.fontFamily = 'Montserrat',
    this.grain = true,
    this.fontBuilder,
  });

  /// Cream paper and dark ink.
  factory PaperThemeData.light({
    String fontFamily = 'Montserrat',
    bool grain = true,
    PaperFontBuilder? fontBuilder,
  }) =>
      PaperThemeData(
        palette: PaperPalette.light,
        fontFamily: fontFamily,
        grain: grain,
        fontBuilder: fontBuilder,
      );

  /// Espresso paper and pale ink.
  factory PaperThemeData.dark({
    String fontFamily = 'Montserrat',
    bool grain = true,
    PaperFontBuilder? fontBuilder,
  }) =>
      PaperThemeData(
        palette: PaperPalette.dark,
        fontFamily: fontFamily,
        grain: grain,
        fontBuilder: fontBuilder,
      );

  /// [PaperThemeData.light] or [PaperThemeData.dark].
  factory PaperThemeData.fromBrightness(
    Brightness brightness, {
    String fontFamily = 'Montserrat',
    bool grain = true,
    PaperFontBuilder? fontBuilder,
  }) =>
      PaperThemeData(
        palette: PaperPalette.of(brightness),
        fontFamily: fontFamily,
        grain: grain,
        fontBuilder: fontBuilder,
      );

  /// The colours.
  final PaperPalette palette;

  /// The font every widget asks for. The kit doesn't bundle fonts: register
  /// Montserrat in your app, or pass [fontBuilder].
  final String fontFamily;

  /// Whether [PaperBackground] paints its paper grain.
  final bool grain;

  /// Applied to every text style the kit builds. Use it to plug in a font package.
  final PaperFontBuilder? fontBuilder;

  /// Whether this is the light or the dark set.
  Brightness get brightness => palette.brightness;

  /// Whether this is the dark set.
  bool get isDark => palette.isDark;

  /// A text style in the kit's font. Every widget builds its text with this.
  TextStyle text({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
    List<FontFeature>? fontFeatures,
  }) {
    final style = TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color ?? palette.ink,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: fontStyle,
      fontFeatures: fontFeatures,
    );
    return fontBuilder == null ? style : fontBuilder!(style);
  }

  /// A Material [ThemeData] in the same colours and font, so Material widgets
  /// sit comfortably next to the kit's.
  ThemeData toMaterialTheme() {
    final p = palette;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.accent,
      onSecondary: p.paper,
      tertiary: p.blueInk,
      onTertiary: p.tabInk,
      error: p.redPen,
      onError: p.tabInk,
      surface: p.sheet,
      onSurface: p.ink,
      onSurfaceVariant: p.muted,
      outline: p.rule,
      outlineVariant: p.rule,
      surfaceContainerHighest: p.paper,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontBuilder == null ? fontFamily : null,
      scaffoldBackgroundColor: p.paper,
      canvasColor: p.paper,
      dividerColor: p.rule,
      splashFactory: NoSplash.splashFactory,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.ink,
        selectionColor: p.accent.withValues(alpha: 0.3),
        selectionHandleColor: p.ink,
      ),
    );
    final builder = fontBuilder;
    if (builder == null) return base;
    TextStyle? apply(TextStyle? style) => style == null ? null : builder(style);
    final t = base.textTheme;
    return base.copyWith(
      textTheme: TextTheme(
        displayLarge: apply(t.displayLarge),
        displayMedium: apply(t.displayMedium),
        displaySmall: apply(t.displaySmall),
        headlineLarge: apply(t.headlineLarge),
        headlineMedium: apply(t.headlineMedium),
        headlineSmall: apply(t.headlineSmall),
        titleLarge: apply(t.titleLarge),
        titleMedium: apply(t.titleMedium),
        titleSmall: apply(t.titleSmall),
        bodyLarge: apply(t.bodyLarge),
        bodyMedium: apply(t.bodyMedium),
        bodySmall: apply(t.bodySmall),
        labelLarge: apply(t.labelLarge),
        labelMedium: apply(t.labelMedium),
        labelSmall: apply(t.labelSmall),
      ),
    );
  }

  /// A copy with some fields replaced.
  PaperThemeData copyWith({
    PaperPalette? palette,
    String? fontFamily,
    bool? grain,
    PaperFontBuilder? fontBuilder,
  }) {
    return PaperThemeData(
      palette: palette ?? this.palette,
      fontFamily: fontFamily ?? this.fontFamily,
      grain: grain ?? this.grain,
      fontBuilder: fontBuilder ?? this.fontBuilder,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaperThemeData &&
      other.palette == palette &&
      other.fontFamily == fontFamily &&
      other.grain == grain &&
      other.fontBuilder == fontBuilder;

  @override
  int get hashCode => Object.hash(palette, fontFamily, grain, fontBuilder);
}

/// Makes a [PaperThemeData] available to the kit's widgets below it.
///
/// Without one, widgets follow the brightness of the surrounding Material [Theme].
class PaperTheme extends InheritedWidget {
  /// Provides [data] to [child].
  const PaperTheme({super.key, required this.data, required super.child});

  /// The theme for this subtree.
  final PaperThemeData data;

  /// The closest [PaperThemeData], or one matching the Material theme's brightness.
  static PaperThemeData of(BuildContext context) {
    return maybeOf(context) ??
        PaperThemeData.fromBrightness(Theme.of(context).brightness);
  }

  /// The closest [PaperThemeData], if there is one.
  static PaperThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PaperTheme>()?.data;
  }

  @override
  bool updateShouldNotify(PaperTheme oldWidget) => data != oldWidget.data;
}
