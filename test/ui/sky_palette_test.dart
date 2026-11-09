import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/domain/condition_map.dart';
import 'package:howeather/ui/sky/sky_background.dart';
import 'package:howeather/ui/sky/sky_palette.dart';

/// The brightest stop of a scene's gradient (worst case for white ink).
Color lightestStop(SkyScene s) =>
    SkyColors.gradient(s)
        .reduce((a, b) => a.computeLuminance() >= b.computeLuminance() ? a : b);

void main() {
  test('contrastRatio follows WCAG (white/black = 21, same = 1)', () {
    expect(
      contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF000000)),
      closeTo(21, 0.01),
    );
    expect(
      contrastRatio(const Color(0xFF777777), const Color(0xFF777777)),
      closeTo(1, 0.001),
    );
  });

  for (final scene in SkyScene.values) {
    test('$scene: every ink on glass over the lightest stop >= 4.5', () {
      final p = SkyPalette.forScene(scene);
      final card = Color.alphaBlend(p.glass, lightestStop(scene));
      for (final (name, ink) in [
        ('ink', p.ink),
        ('inkSoft', p.inkSoft),
        ('inkFaint', p.inkFaint),
      ]) {
        expect(
          contrastRatio(Color.alphaBlend(ink, card), card),
          greaterThanOrEqualTo(4.5),
          reason: '$scene $name on glass ${p.glass}',
        );
      }
    });
  }

  test('inks over the sky are white, visibly ordered ink > soft > faint', () {
    for (final scene in SkyScene.values) {
      final p = SkyPalette.forScene(scene);
      for (final c in [p.ink, p.inkSoft, p.inkFaint]) {
        expect((c.r, c.g, c.b), (1.0, 1.0, 1.0));
      }
      expect(p.ink.a, 1.0);
      expect(p.ink.a - p.inkSoft.a, greaterThanOrEqualTo(0.1));
      expect(p.inkSoft.a - p.inkFaint.a, greaterThanOrEqualTo(0.1));
    }
  });

  test('dark scenes use white glass; bright day scenes a darker tint', () {
    final night = SkyPalette.forScene(SkyScene.rainNight);
    expect(night.glass.r, 1.0);
    expect(night.glass.a, inInclusiveRange(0.10, 0.14));
    expect(night.glassLine, const Color(0x24FFFFFF));
    final day = SkyPalette.forScene(SkyScene.clearDay);
    expect(day.glass.computeLuminance(), lessThan(0.05));
    expect(day.glass.a, greaterThanOrEqualTo(0.18));
  });

  testWidgets('SkyPaletteScope provides the palette and a dark sky theme', (
    t,
  ) async {
    late SkyPalette got;
    late ThemeData theme;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: SkyPaletteScope(
          palette: SkyPalette.forScene(SkyScene.clearDay),
          child: Builder(
            builder: (context) {
              got = SkyPalette.of(context);
              theme = Theme.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(got.scene, SkyScene.clearDay);
    expect(theme.colorScheme.onSurface, got.ink);
    expect(theme.colorScheme.onSurfaceVariant, got.inkSoft);
    expect(theme.brightness, Brightness.dark);
  });
}
