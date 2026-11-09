import 'package:flutter/material.dart';

/// Design tokens shared with the approved home mockup.
class AppTokens {
  AppTokens._();

  static const skyDayTop = Color(0xFF2F7EC4);
  static const skyDayBottom = Color(0xFF9FD0EF);
  static const skyNightTop = Color(0xFF0B1F38);
  static const skyNightBottom = Color(0xFF1C3A5C);
  static const accent = Color(0xFFFFC24B);

  // Spacing system: 4-pt grid.
  /// Corner radius of big cards.
  static const radius = 22.0;

  /// Corner radius of tiles and rows inside cards.
  static const radiusTile = 16.0;

  /// Horizontal page gutter.
  static const gutter = 16.0;

  /// Gap between cards (vertical and between paired 2-up cards).
  static const cardGap = 12.0;

  /// Inner padding of a card.
  static const cardPadding = 16.0;

  static Color ink(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFEAF2FB) : const Color(0xFF0F2238);
  static Color inkSoft(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFA9BFD6) : const Color(0xFF43586E);

  /// Glass card fill: white 22% (light) / #122034 at 42% (dark).
  static Color glass(Brightness b) =>
      b == Brightness.dark ? const Color(0x6B122034) : const Color(0x38FFFFFF);
  static Color glassLine(Brightness b) =>
      b == Brightness.dark ? const Color(0x24FFFFFF) : const Color(0x61FFFFFF);
}

ThemeData buildTheme(Brightness b) {
  final ink = AppTokens.ink(b);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppTokens.skyDayTop,
        brightness: b,
      ).copyWith(
        secondary: AppTokens.accent,
        onSurface: ink,
        onSurfaceVariant: AppTokens.inkSoft(b),
      );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: b == Brightness.dark
        ? AppTokens.skyNightBottom
        : AppTokens.skyDayBottom,
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    iconTheme: IconThemeData(color: ink),
    cardTheme: CardThemeData(
      color: AppTokens.glass(b),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(color: AppTokens.glassLine(b)),
      ),
    ),
  );
}
