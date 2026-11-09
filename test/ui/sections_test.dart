import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/data/text_translator.dart';
import 'package:howeather/domain/alerts.dart';
import 'package:howeather/domain/models.dart';
import 'package:howeather/state/providers.dart';
import 'package:howeather/l10n/gen/app_localizations.dart';
import 'package:howeather/ui/cards/alert_card.dart';
import 'package:howeather/ui/cards/metric_card.dart';
import 'package:howeather/ui/cards/sun_card.dart';

import 'cards_test.dart' show host, load;

DailyPoint day({
  String sunrise = '06:00',
  String sunset = '18:30',
  String moon = 'Waxing Gibbous',
}) => DailyPoint(
  date: DateTime.utc(2026, 11, 9),
  minC: 10,
  maxC: 20,
  uv: 5,
  chanceOfRain: 0,
  condition: const Condition(code: 1000, text: 'Sunny', isDay: true),
  sunrise: sunrise,
  sunset: sunset,
  moonPhase: moon,
);

const alertMinor = WeatherAlert(
  headline: 'Fog advisory until 10 AM',
  severity: 'Moderate',
  event: 'Fog Advisory',
  desc: 'Visibility below 200 m.',
);
const alertSevere = WeatherAlert(
  headline: 'Severe thunderstorm warning',
  severity: 'Severe',
  event: 'Thunderstorm Warning',
  desc: 'Hail and damaging winds.',
);

void main() {
  late AppLocalizations en;
  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('state labels', () {
    test('humidity bands', () {
      expect(humidityLabel(en, 20), en.humidityDry);
      expect(humidityLabel(en, 45), en.humidityComfortable);
      expect(humidityLabel(en, 80), en.humidityHumid);
    });
    test('pressure bands', () {
      expect(pressureLabel(en, 1000), en.pressureLow);
      expect(pressureLabel(en, 1015), en.pressureNormal);
      expect(pressureLabel(en, 1030), en.pressureHigh);
    });
    test('visibility bands', () {
      expect(visibilityLabel(en, 0.5), en.visPoor);
      expect(visibilityLabel(en, 2), en.visFair);
      expect(visibilityLabel(en, 6), en.visGood);
      expect(visibilityLabel(en, 10), en.visExcellent);
    });
  });

  group('sun card helpers', () {
    test('daylight minutes', () {
      expect(daylightMinutes(day()), 12 * 60 + 30);
      expect(daylightMinutes(day(sunrise: '', sunset: '18:00')), isNull);
    });
    test('moon phase parsing accepts API spellings', () {
      expect(moonPhaseOf('Waxing Gibbous'), MoonPhase.waxingGibbous);
      expect(moonPhaseOf('Third Quarter'), MoonPhase.lastQuarter);
      expect(moonPhaseOf(' full moon '), MoonPhase.fullMoon);
      expect(moonPhaseOf('Blue Moon'), isNull);
    });
  });

  testWidgets('metric cards show a range bar and a state pill', (t) async {
    final london = load('forecast_london.json');
    await t.pumpWidget(
      host(
        Column(
          children: [
            MetricCard.pressure(1015),
            MetricCard.visibility(10),
            MetricCard.humidity(london.current, TempUnit.c),
            MetricCard.uv(2, peak: 6),
          ],
        ),
      ),
    );
    expect(find.byType(ScaleBar), findsNWidgets(4));
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.text("Today's peak 6"), findsOneWidget);
    expect(find.text('29.97 inHg'), findsOneWidget);
  });

  testWidgets('UV peak is hidden when it is not above now', (t) async {
    await t.pumpWidget(host(MetricCard.uv(6, peak: 6)));
    expect(find.textContaining('peak'), findsNothing);
  });

  testWidgets('wind pill carries a direction arrow', (t) async {
    final london = load('forecast_london.json');
    await t.pumpWidget(host(MetricCard.wind(london.current, WindUnit.kmh)));
    expect(find.byKey(const ValueKey('windArrow')), findsOneWidget);
  });

  testWidgets('scale marker sits at the start edge in RTL for 0', (t) async {
    await t.pumpWidget(
      host(
        const SizedBox(
          width: 200,
          child: ScaleBar(position: 0, colors: [Colors.green, Colors.red]),
        ),
        locale: const Locale('ar'),
      ),
    );
    final bar = t.getRect(find.byType(ScaleBar));
    final marker = t.getRect(find.byKey(const ValueKey('scaleMarker')));
    expect(marker.right, closeTo(bar.right, 0.5));
  });

  testWidgets('sun card footer: daylight and moon phase', (t) async {
    await t.pumpWidget(host(SunCard(day(), DateTime.utc(2026, 11, 9, 12))));
    expect(find.text('Daylight 12h 30m'), findsOneWidget);
    expect(find.text('Waxing gibbous'), findsOneWidget);
    expect(find.byKey(const ValueKey('moonPhaseIcon')), findsOneWidget);
  });

  testWidgets('sun card without a known moon phase shows no moon', (t) async {
    await t.pumpWidget(
      host(SunCard(day(moon: ''), DateTime.utc(2026, 11, 9, 12))),
    );
    expect(find.byKey(const ValueKey('moonPhaseIcon')), findsNothing);
    expect(find.text('Daylight 12h 30m'), findsOneWidget);
  });

  group('alert language', () {
    const persian = 'افزایش سرعت وزش باد و افزایش ارتفاع امواج دریا';
    const arabic = 'رياح نشطة وارتفاع الأمواج على السواحل';
    test('script detection', () {
      expect(textMatchesLanguage('Fog advisory', 'en'), isTrue);
      expect(textMatchesLanguage(persian, 'en'), isFalse);
      expect(textMatchesLanguage(persian, 'ar'), isFalse);
      expect(textMatchesLanguage(arabic, 'ar'), isTrue);
      expect(textMatchesLanguage(arabic, 'en'), isFalse);
      expect(textMatchesLanguage('Fog advisory', 'ar'), isFalse);
    });

    const foreign = WeatherAlert(
      headline: persian,
      severity: 'Moderate',
      event: 'هشدار دریایی',
      desc: 'هشدار هواشناسی دریایی',
    );

    Widget scoped(Widget child, TextTranslator t, {Locale? locale}) =>
        ProviderScope(
          overrides: [textTranslatorProvider.overrideWithValue(t)],
          child: locale == null ? host(child) : host(child, locale: locale),
        );

    testWidgets('foreign alert is shown translated', (t) async {
      await t.pumpWidget(scoped(const AlertCard([foreign]), _FakeTranslator()));
      expect(find.text('Translating…'), findsOneWidget);
      await t.pumpAndSettle();
      expect(find.text('[en] هشدار دریایی'), findsOneWidget);
      expect(find.textContaining('افزایش'), findsOneWidget); // in [en] headline

      await t.tap(find.byKey(const ValueKey('alertCard')));
      await t.pumpAndSettle();
      expect(find.text('Translated automatically'), findsOneWidget);
    });

    testWidgets('translation failure falls back to the labelled original', (
      t,
    ) async {
      await t.pumpWidget(
        scoped(const AlertCard([foreign]), _FailingTranslator()),
      );
      await t.pumpAndSettle();
      expect(find.text('Weather alert'), findsOneWidget);
      expect(find.textContaining("Couldn't translate"), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('alertCard')));
      await t.pumpAndSettle();
      expect(find.text('Original text'), findsOneWidget);
      final body = find.textContaining('هشدار هواشناسی');
      expect(t.widget<Text>(body).textDirection, TextDirection.rtl);
    });

    testWidgets('alerts already in the app language skip translation', (
      t,
    ) async {
      final translator = _FakeTranslator();
      await t.pumpWidget(scoped(const AlertCard([alertMinor]), translator));
      await t.pumpAndSettle();
      expect(find.text('Fog Advisory'), findsOneWidget);
      expect(translator.calls, 0);
    });
  });

  test('place names are translated only for Arabic, from English', () async {
    final translator = _FakeTranslator();
    final c = ProviderContainer(
      overrides: [textTranslatorProvider.overrideWithValue(translator)],
    );
    addTearDown(c.dispose);
    expect(
      await c.read(placeNameProvider(('Khartoum', 'en')).future),
      'Khartoum',
    );
    expect(
      await c.read(placeNameProvider(('Khartoum', 'ar')).future),
      '[ar] Khartoum',
    );
    expect(translator.lastFrom, 'en');
    expect(
      await c.read(placeNameProvider(('الخرطوم', 'ar')).future),
      'الخرطوم',
    );
    expect(translator.calls, 1);
  });

  testWidgets('alert card leads with the severe alert and expands', (t) async {
    await t.pumpWidget(
      ProviderScope(child: host(const AlertCard([alertMinor, alertSevere]))),
    );
    expect(find.text('Thunderstorm Warning'), findsOneWidget);
    expect(find.text('+1 more'), findsOneWidget);
    expect(find.textContaining('Hail'), findsNothing);

    await t.tap(find.byKey(const ValueKey('alertCard')));
    await t.pumpAndSettle();
    expect(find.text('+1 more'), findsNothing);
    expect(find.textContaining('Hail and damaging winds.'), findsOneWidget);
    expect(find.text('Fog Advisory'), findsOneWidget);
    expect(find.textContaining('Visibility below 200 m.'), findsOneWidget);
  });
}

class _FakeTranslator implements TextTranslator {
  var calls = 0;
  String? lastFrom;
  @override
  Future<String> translate(
    String text,
    String targetLang, {
    String? from,
  }) async {
    calls++;
    lastFrom = from;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return '[$targetLang] $text';
  }
}

class _FailingTranslator implements TextTranslator {
  @override
  Future<String> translate(
    String text,
    String targetLang, {
    String? from,
  }) async => throw const TranslationUnavailable('offline');
}
