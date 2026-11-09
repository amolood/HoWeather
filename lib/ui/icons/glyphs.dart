import 'package:flutter/widgets.dart';

import 'line_icon.dart';

/// Life-advice glyphs (first six) and UI glyphs.
enum Glyph {
  dress,
  carWash,
  sport,
  umbrella,
  sunCream,
  allergy,
  wind,
  humidity,
  pressure,
  visibility,
  uv,
  air,
  sunrise,
  pin,
  search,
  menu,
  plus,
  settings,
  dragHandle,
  trash,
  check,

  /// Points to the right (LTR "forward"); mirror it in RTL.
  chevron,
  globe,
  refresh,
  appearance,
  info,
  thermometer,
}

const Map<Glyph, LineShape> _shapes = {
  Glyph.dress: LineShape(['M8 3l4 2 4-2 3 3-3 3v10H8V9L5 6z']),
  Glyph.carWash: LineShape(
    [
      'M4 13l1.5-4.5A2 2 0 0 1 7.4 7h9.2a2 2 0 0 1 1.9 1.5L20 13v5h-2v-2H6v2H4z',
      'M8 4.5c0 1-1 1-1 2M12 4c0 1-1 1-1 2M16 4.5c0 1-1 1-1 2',
    ],
    [(7.5, 16, 1), (16.5, 16, 1)],
  ),
  Glyph.sport: LineShape(
    [
      'M12 3a9 9 0 0 0 0 18M3 12a9 9 0 0 0 18 0M5 6c3 2 11 2 14 0M5 18c3-2 11-2 14 0',
    ],
    [(12, 12, 9)],
  ),
  Glyph.umbrella: LineShape([
    'M12 3v2M3.5 11a8.5 8.5 0 0 1 17 0z',
    'M12 11v7a2.5 2.5 0 0 0 5 0',
  ]),
  Glyph.sunCream: LineShape([
    'M9 9h6v10.5a1.5 1.5 0 0 1-1.5 1.5h-3A1.5 1.5 0 0 1 9 19.5z',
    'M10 9V6h4v3M12 3v3M9 14h6',
  ]),
  Glyph.allergy: LineShape([
    'M12 20c3.8 0 6-2.4 6-5.5 0-3.6-3-7-6-11-3 4-6 7.4-6 11C6 17.6 8.2 20 12 20z',
  ]),
  Glyph.wind: LineShape([
    'M3 9h11a2.5 2.5 0 1 0-2.5-2.5M3 13h15a2.5 2.5 0 1 1-2.5 2.5M3 17h7',
  ]),
  Glyph.humidity: LineShape([
    'M12 3c3 4 6 7.4 6 11a6 6 0 0 1-12 0c0-3.6 3-7 6-11z',
    'M9 14.5a3 3 0 0 0 3 3',
  ]),
  Glyph.pressure: LineShape(
    ['M4 17a8 8 0 1 1 16 0', 'M12 17l3.5-4.5M4 17h2M18 17h2'],
    [(12, 17, 1)],
  ),
  Glyph.visibility: LineShape(
    ['M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z'],
    [(12, 12, 3)],
  ),
  Glyph.uv: LineShape(
    [
      'M12 3v1.5M12 19.5V21M4.5 12H3M21 12h-1.5M6 6l1 1M17 17l1 1M6 18l1-1M17 7l1-1',
    ],
    [(12, 12, 3.4)],
  ),
  Glyph.air: LineShape([
    'M3 8c3-3 5 3 9 0s6 3 9 0M3 13c3-3 5 3 9 0s6 3 9 0M3 18c3-3 5 3 9 0s6 3 9 0',
  ]),
  Glyph.sunrise: LineShape([
    'M3 19h18M7 19a5 5 0 0 1 10 0',
    'M12 5v5M9.5 7.5L12 5l2.5 2.5M4.6 12.6l1.4 1.4M19.4 12.6L18 14',
  ]),
  Glyph.pin: LineShape(
    ['M12 21s6.5-6 6.5-11a6.5 6.5 0 0 0-13 0c0 5 6.5 11 6.5 11z'],
    [(12, 10, 2.4)],
  ),
  Glyph.search: LineShape(['M16 16l5 5'], [(11, 11, 6.5)]),
  Glyph.menu: LineShape(['M4 7h16M4 12h16M4 17h16']),
  Glyph.plus: LineShape(['M12 5v14M5 12h14']),
  Glyph.settings: LineShape(
    ['M4 7h9M17 7h3M4 17h3M11 17h9'],
    [(15, 7, 2), (9, 17, 2)],
  ),
  Glyph.dragHandle: LineShape(['M5 9.5h14M5 14.5h14']),
  Glyph.trash: LineShape([
    'M4 7h16M10 7V4.5h4V7',
    'M6.5 7l1 12.5a1.5 1.5 0 0 0 1.5 1.5h6a1.5 1.5 0 0 0 1.5-1.5L17.5 7',
    'M10 11v6M14 11v6',
  ]),
  Glyph.check: LineShape(['M5 12.5l4.5 4.5L19 7.5']),
  Glyph.chevron: LineShape(['M9 5l7 7-7 7']),
  Glyph.globe: LineShape(
    [
      'M3 12h18',
      'M12 3c2.5 2.6 3.8 5.6 3.8 9s-1.3 6.4-3.8 9c-2.5-2.6-3.8-5.6-3.8-9S9.5 5.6 12 3z',
    ],
    [(12, 12, 9)],
  ),
  Glyph.refresh: LineShape(['M20 12a8 8 0 1 1-2.4-5.7M20 4v5h-5']),
  Glyph.appearance: LineShape(['M12 3v18'], [(12, 12, 9)]),
  Glyph.info: LineShape(['M12 11v6M12 7.5v.01'], [(12, 12, 9)]),
  Glyph.thermometer: LineShape(['M10 14V5a2 2 0 0 1 4 0v9'], [(12, 17, 3)]),
};

LineShape glyphShape(Glyph g) => _shapes[g]!;

/// Glyphs that have a monochrome image in assets/icons/ (from the app's
/// drawable set). They are tinted with the requested color, so they follow
/// the sky palette the same way the vector glyphs do. Others fall back to
/// the vector path in [_shapes].
const Map<Glyph, String> _assets = {
  Glyph.uv: 'assets/icons/glyph_uv.webp',
  Glyph.air: 'assets/icons/glyph_air.webp',
  Glyph.wind: 'assets/icons/glyph_wind.webp',
  Glyph.humidity: 'assets/icons/glyph_humidity.webp',
  Glyph.pressure: 'assets/icons/glyph_pressure.webp',
  Glyph.visibility: 'assets/icons/glyph_visibility.webp',
  Glyph.carWash: 'assets/icons/glyph_car_wash.webp',
  Glyph.umbrella: 'assets/icons/glyph_umbrella.webp',
  Glyph.allergy: 'assets/icons/glyph_allergy.webp',
  Glyph.sport: 'assets/icons/glyph_sport.webp',
  Glyph.sunrise: 'assets/icons/glyph_sunrise.webp',
  Glyph.chevron: 'assets/icons/glyph_chevron.webp',
  Glyph.thermometer: 'assets/icons/glyph_thermometer.webp',
};

class GlyphView extends StatelessWidget {
  final Glyph glyph;
  final double size;
  final Color? color;
  const GlyphView(this.glyph, {super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    final asset = _assets[glyph];
    if (asset == null) {
      return LineIconBox(shape: glyphShape(glyph), size: size, color: color);
    }
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    return Image.asset(
      asset,
      width: size,
      height: size,
      color: c,
      colorBlendMode: BlendMode.srcIn,
      excludeFromSemantics: true,
    );
  }
}
