import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/ui/icons/glyphs.dart';
import 'package:howeather/ui/icons/line_icon.dart';
import 'package:howeather/ui/icons/wx_icons.dart';

void main() {
  testWidgets('every WxIcon and Glyph renders without error', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final i in WxIcon.values) WxIconView(i),
              for (final g in Glyph.values) GlyphView(g, color: Colors.red),
            ],
          ),
        ),
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.byType(WxIconView), findsNWidgets(WxIcon.values.length));
    expect(find.byType(GlyphView), findsNWidgets(Glyph.values.length));
  });

  test('every shape parses and stays on the 24 grid (2px tolerance for arc control boxes)', () {
    final shapes = [
      for (final i in WxIcon.values) wxShape(i),
      for (final g in Glyph.values) glyphShape(g),
    ];
    for (final s in shapes) {
      for (final d in s.paths) {
        final b = parseSvgPath(d).getBounds();
        expect(b.isEmpty && b.width == 0 && b.height == 0, isFalse);
        expect(b.left, greaterThanOrEqualTo(-2));
        expect(b.top, greaterThanOrEqualTo(-2));
        expect(b.right, lessThanOrEqualTo(26));
        expect(b.bottom, lessThanOrEqualTo(26));
      }
    }
  });

  test('Glyph contains the life and UI glyph names', () {
    expect(
      Glyph.values.map((g) => g.name),
      containsAll([
        'dress',
        'carWash',
        'sport',
        'umbrella',
        'sunCream',
        'allergy',
        'wind',
        'humidity',
        'pressure',
        'visibility',
        'uv',
        'air',
        'sunrise',
        'pin',
        'search',
        'menu',
        'plus',
        'settings',
        'dragHandle',
        'trash',
        'check',
        'chevron',
      ]),
    );
  });
}
