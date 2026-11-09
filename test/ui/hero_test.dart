import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/data/prefs_store.dart';
import 'package:howeather/data/weather_mapper.dart';
import 'package:howeather/domain/condition_map.dart';
import 'package:howeather/domain/models.dart';
import 'package:howeather/l10n/gen/app_localizations.dart';
import 'package:howeather/ui/cards/current_hero.dart';
import 'package:howeather/ui/sky/sky_palette.dart';
import 'package:howeather/ui/theme.dart';

const settingsC = Settings(
  temp: TempUnit.c,
  wind: WindUnit.kmh,
  refresh: Duration(hours: 1),
  theme: ThemePref.system,
);

void main() {
  final london = mapForecast(
    jsonDecode(File('test/fixtures/forecast_london.json').readAsStringSync())
        as Map<String, dynamic>,
    fetchedAt: DateTime.utc(2026, 11, 9, 17, 40),
  );

  Color colorOf(WidgetTester t, Finder f) =>
      t.renderObject<RenderParagraph>(f).text.style!.color!;

  for (final scene in [SkyScene.clearDay, SkyScene.rainNight]) {
    for (final brightness in Brightness.values) {
      testWidgets('hero text is white in $scene ($brightness theme)', (
        t,
      ) async {
        await t.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildTheme(brightness),
            home: Scaffold(
              body: SkyPaletteScope(
                palette: SkyPalette.forScene(scene),
                child: CurrentHero(london, settingsC),
              ),
            ),
          ),
        );
        final temp = find.text('9'); // 9.2 C rounded
        final condition = find.text(london.current.condition.text);
        expect(temp, findsOneWidget);
        expect(condition, findsOneWidget);
        expect(find.text('°'), findsOneWidget);
        for (final f in [temp, condition]) {
          final c = colorOf(t, f);
          expect((c.r, c.g, c.b), (1.0, 1.0, 1.0));
          expect(c.a, greaterThanOrEqualTo(0.9));
        }
        final size = t
            .renderObject<RenderParagraph>(temp)
            .text
            .style!
            .fontSize!;
        expect(size, greaterThanOrEqualTo(90));
        expect(find.text('H 12° · L 5°'), findsOneWidget);
        expect(find.text('Feels like 8°'), findsOneWidget);
      });
    }
  }
}
