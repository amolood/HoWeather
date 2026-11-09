import 'package:flutter/material.dart';

import '../../domain/condition_map.dart';
import 'sky_background.dart';

/// WCAG 2.x contrast ratio between two opaque colours (1..21).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Colours for everything drawn over the sky (hero, top bar, cards, footer).
///
/// Derived from the visible city's [SkyScene], never from the app ThemeMode:
/// the sky is the background, so the ink is always light.
@immutable
class SkyPalette {
  final SkyScene scene;

  /// Primary ink (white 100%), secondary (~86%) and tertiary (~74%).
  /// The lower two are as faint as they can be while small text still
  /// reaches 4.5:1 on the derived glass.
  final Color ink, inkSoft, inkFaint;

  /// Card glass fill and its 1 px border.
  final Color glass, glassLine;

  /// Translucent fill for small pills/chips on glass.
  final Color pill;

  /// Fill behind the top bar once content scrolls under it.
  final Color barFill;

  const SkyPalette._({
    required this.scene,
    required this.glass,
    required this.glassLine,
    required this.barFill,
  }) : ink = const Color(0xFFFFFFFF),
       inkSoft = _inkSoft,
       inkFaint = _inkFaint,
       pill = const Color(0x2EFFFFFF);

  /// Soft shadow that keeps white text legible directly on the sky.
  static const textShadow = [Shadow(color: Color(0x4D000000), blurRadius: 8)];

  /// Minimum WCAG contrast of every ink on glass over the brightest stop.
  static const minContrast = 4.5;

  static const _inkSoft = Color(0xDBFFFFFF); // white 86%
  static const _inkFaint = Color(0xBDFFFFFF); // white 74%

  static const _whiteGlass = Color(0x1FFFFFFF); // white 12%
  static const _whiteLine = Color(0x24FFFFFF); // white 14%
  static const _tint = Color(0xFF0A1E3C); // deep navy for bright skies
  static const _tintLine = Color(0x2EFFFFFF);
  static const _minTintAlpha = 0.18;

  static final Map<SkyScene, SkyPalette> _cache = {};

  /// Dark scenes get white 12% glass; brighter scenes a navy tint starting
  /// at 18% and darkened just enough for every ink (down to [inkFaint]) to
  /// keep >= 4.5:1 (plus a small margin) over the scene's lightest stop.
  factory SkyPalette.forScene(SkyScene scene) =>
      _cache.putIfAbsent(scene, () => _derive(scene));

  static SkyPalette _derive(SkyScene scene) {
    const target = minContrast + 0.1;
    final stops = SkyColors.gradient(scene);
    final lightest = stops.reduce(
      (a, b) => a.computeLuminance() >= b.computeLuminance() ? a : b,
    );
    // The faintest ink is the binding constraint.
    bool legible(Color glass) {
      final card = Color.alphaBlend(glass, lightest);
      return contrastRatio(Color.alphaBlend(_inkFaint, card), card) >= target;
    }

    final bar = stops.first.withValues(alpha: 0.85);
    if (legible(_whiteGlass)) {
      return SkyPalette._(
        scene: scene,
        glass: _whiteGlass,
        glassLine: _whiteLine,
        barFill: bar,
      );
    }
    var alpha = _minTintAlpha;
    while (alpha < 1 && !legible(_tint.withValues(alpha: alpha))) {
      alpha += 0.01;
    }
    return SkyPalette._(
      scene: scene,
      glass: _tint.withValues(alpha: alpha.clamp(0, 1)),
      glassLine: _tintLine,
      barFill: bar,
    );
  }

  /// The nearest scope's palette; clear day when there is none.
  static SkyPalette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SkyPaletteScope>()?.palette ??
      SkyPalette.forScene(SkyScene.clearDay);

  /// [base] with light ink, so Material defaults inside the sky match.
  ThemeData theme(ThemeData base) {
    final scheme = base.colorScheme.copyWith(
      brightness: Brightness.dark,
      onSurface: ink,
      onSurfaceVariant: inkSoft,
    );
    return base.copyWith(
      colorScheme: scheme,
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      iconTheme: IconThemeData(color: ink),
    );
  }
}

/// Provides a [SkyPalette] and the matching light-ink theme to its subtree.
class SkyPaletteScope extends InheritedWidget {
  final SkyPalette palette;

  SkyPaletteScope({super.key, required this.palette, required Widget child})
    : super(
        child: Builder(
          builder: (context) => Theme(
            data: palette.theme(Theme.of(context)),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: palette.ink),
              child: child,
            ),
          ),
        ),
      );

  @override
  bool updateShouldNotify(SkyPaletteScope old) => old.palette != palette;
}
