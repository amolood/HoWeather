import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:howeather/data/prefs_store.dart';
import 'package:howeather/data/weather_mapper.dart';
import 'package:howeather/domain/life_index.dart';
import 'package:howeather/domain/models.dart';
import 'package:howeather/l10n/gen/app_localizations.dart';
import 'package:howeather/ui/cards/brief_card.dart';
import 'package:howeather/ui/cards/current_hero.dart';
import 'package:howeather/ui/cards/daily_card.dart';
import 'package:howeather/ui/cards/hourly_card.dart';
import 'package:howeather/ui/cards/metric_card.dart';
import 'package:howeather/ui/cards/sun_card.dart';
import 'package:howeather/ui/theme.dart';

WeatherBundle load(String name) => mapForecast(
  jsonDecode(File('test/fixtures/$name').readAsStringSync())
      as Map<String, dynamic>,
  fetchedAt: DateTime.utc(2026, 11, 9, 17, 40),
);

const settingsC = Settings(
  temp: TempUnit.c,
  wind: WindUnit.kmh,
  refresh: Duration(hours: 1),
  theme: ThemePref.system,
);

/// London fixture with the current temperature set to 10.0 C (the fixture
/// itself reports 9.2 C), so the hero reads 10 C / 50 F.
WeatherBundle withTemp(WeatherBundle b, double tempC) {
  final c = b.current;
  return WeatherBundle(
    cityName: b.cityName,
    region: b.region,
    country: b.country,
    tzId: b.tzId,
    lat: b.lat,
    lon: b.lon,
    utcOffset: b.utcOffset,
    current: CurrentWeather(
      tempC: tempC,
      feelsLikeC: c.feelsLikeC,
      windKph: c.windKph,
      gustKph: c.gustKph,
      pressureMb: c.pressureMb,
      visKm: c.visKm,
      uv: c.uv,
      dewPointC: c.dewPointC,
      humidity: c.humidity,
      windDegree: c.windDegree,
      cloud: c.cloud,
      windDir: c.windDir,
      condition: c.condition,
      air: c.air,
      updatedAt: c.updatedAt,
    ),
    hourly: b.hourly,
    daily: b.daily,
    alerts: b.alerts,
    fetchedAt: b.fetchedAt,
  );
}

CurrentWeather windAt(CurrentWeather c, double kph) => CurrentWeather(
  tempC: c.tempC,
  feelsLikeC: c.feelsLikeC,
  windKph: kph,
  gustKph: c.gustKph,
  pressureMb: c.pressureMb,
  visKm: c.visKm,
  uv: c.uv,
  dewPointC: c.dewPointC,
  humidity: c.humidity,
  windDegree: c.windDegree,
  cloud: c.cloud,
  windDir: c.windDir,
  condition: c.condition,
  air: c.air,
  updatedAt: c.updatedAt,
);

Widget host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: buildTheme(Brightness.light),
  home: Scaffold(
    backgroundColor: AppTokens.skyDayTop,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

List<Widget> allCards(WeatherBundle b, Settings s) {
  final today = b.daily.first;
  return [
    CurrentHero(b, s),
    HourlyCard(b.hourly, s, toCityTime: b.toCityTime),
    DailyCard(b.daily, s),
    Row(
      children: [
        Expanded(child: MetricCard.aqi(b.current.air)),
        const SizedBox(width: 14),
        Expanded(child: MetricCard.uv(today.uv)),
      ],
    ),
    Row(
      children: [
        Expanded(child: MetricCard.wind(b.current, s.wind)),
        const SizedBox(width: 14),
        Expanded(child: MetricCard.humidity(b.current, s.temp)),
      ],
    ),
    Row(
      children: [
        Expanded(child: MetricCard.pressure(b.current.pressureMb)),
        const SizedBox(width: 14),
        Expanded(child: MetricCard.visibility(b.current.visKm)),
      ],
    ),
    SunCard(today, b.toCityTime(b.fetchedAt)),
    BriefCard(
      deriveLifeIndices(
        b.current,
        today,
        b.daily.length > 1 ? b.daily[1] : null,
      ),
    ),
  ];
}

bool hasEmoji(String s) => s.runes.any(
  (r) => (r >= 0x1F300 && r <= 0x1FAFF) || (r >= 0x2600 && r <= 0x27BF),
);

void main() {
  setUp(() => DateFormat.useNativeDigitsByDefaultFor('ar', false));

  final london = load('forecast_london.json');
  final threeDay = load('forecast_3day_noaqi.json');

  testWidgets('hero shows rounded temp in C and F', (t) async {
    final b = withTemp(london, 10.0);
    // The number and its (smaller, top-aligned) degree sign are separate.
    await t.pumpWidget(host(CurrentHero(b, settingsC)));
    expect(find.text('10'), findsOneWidget);
    expect(find.text('°'), findsOneWidget);
    await t.pumpWidget(
      host(CurrentHero(b, settingsC.copyWith(temp: TempUnit.f))),
    );
    expect(find.text('50'), findsOneWidget);
    expect(find.text('10'), findsNothing);
  });

  testWidgets('hero rounds the raw fixture temperature (9.2 C)', (t) async {
    await t.pumpWidget(host(CurrentHero(london, settingsC)));
    expect(find.text('9'), findsOneWidget);
    expect(find.text('°'), findsOneWidget);
  });

  testWidgets('DailyCard renders one row per returned day', (t) async {
    await t.pumpWidget(host(DailyCard(london.daily, settingsC)));
    expect(find.byType(DailyRow), findsNWidgets(14));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('14-day forecast'.toUpperCase()), findsOneWidget);

    await t.pumpWidget(host(DailyCard(threeDay.daily, settingsC)));
    expect(find.byType(DailyRow), findsNWidgets(3));
    expect(find.text('3-day forecast'.toUpperCase()), findsOneWidget);
  });

  testWidgets('MetricCard.aqi(null) shows a dash', (t) async {
    await t.pumpWidget(host(MetricCard.aqi(null)));
    expect(find.text('—'), findsOneWidget);
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('MetricCard.aqi shows EPA index and category', (t) async {
    await t.pumpWidget(host(MetricCard.aqi(london.current.air)));
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('Moderate'), findsOneWidget);
  });

  testWidgets('MetricCard: big light value, label, info line and pill', (
    t,
  ) async {
    await t.pumpWidget(host(MetricCard.aqi(london.current.air)));
    final value = t.renderObject<RenderParagraph>(find.text('2')).text.style!;
    expect(value.fontSize, inInclusiveRange(44, 52));
    expect(value.fontWeight, FontWeight.w300);
    expect(value.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(find.text('AIR QUALITY'), findsOneWidget);
    // Category in the bottom-end pill, pollutant on the bottom-start line.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cardPill')),
        matching: find.text('Moderate'),
      ),
      findsOneWidget,
    );
    expect(find.text('PM2.5 19.5'), findsOneWidget);
    final pill = t.getRect(find.byKey(const ValueKey('cardPill')));
    final info = t.getRect(find.text('PM2.5 19.5'));
    expect(pill.left, greaterThan(info.right)); // LTR: pill at the end
    expect((pill.center.dy - info.center.dy).abs(), lessThan(8));
  });

  testWidgets('paired MetricCards share one height', (t) async {
    await t.pumpWidget(
      host(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: MetricCard.pressure(1015)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard.wind(london.current, WindUnit.kmh)),
            ],
          ),
        ),
      ),
    );
    final a = t.getRect(find.byType(MetricCard).first);
    final b = t.getRect(find.byType(MetricCard).last);
    expect(a.height, b.height);
  });

  testWidgets('wind in m/s shows 3.3 for 11.9 kph', (t) async {
    await t.pumpWidget(
      host(MetricCard.wind(windAt(london.current, 11.9), WindUnit.ms)),
    );
    expect(find.text('3.3'), findsOneWidget);
    expect(find.text('m/s'), findsOneWidget);
  });

  testWidgets('BriefCard shows 6 tiles', (t) async {
    final idx = deriveLifeIndices(
      london.current,
      london.daily[0],
      london.daily[1],
    );
    await t.pumpWidget(host(BriefCard(idx)));
    expect(find.byType(BriefTile), findsNWidgets(6));
  });

  testWidgets('hourly labels use city time, first is Now', (t) async {
    await t.pumpWidget(
      host(HourlyCard(london.hourly, settingsC, toCityTime: london.toCityTime)),
    );
    expect(find.text('Now'), findsOneWidget);
    final second = london.toCityTime(london.hourly[1].time);
    expect(find.text(second.hour.toString().padLeft(2, '0')), findsOneWidget);
  });

  test('sunProgress clamps and interpolates in city time', () {
    final d = london.daily.first; // 07:08 -> 16:20
    expect(sunProgress(d, DateTime.utc(2026, 11, 9, 5)), 0);
    expect(sunProgress(d, DateTime.utc(2026, 11, 9, 20)), 1);
    expect(
      sunProgress(d, DateTime.utc(2026, 11, 9, 11, 44)),
      closeTo(0.5, 0.001),
    );
  });

  testWidgets('no Text contains an emoji code point', (t) async {
    await t.pumpWidget(host(Column(children: allCards(london, settingsC))));
    final texts = [
      for (final w in t.widgetList<Text>(find.byType(Text)))
        w.data ?? w.textSpan?.toPlainText() ?? '',
      for (final w in t.widgetList<RichText>(find.byType(RichText)))
        w.text.toPlainText(),
    ];
    expect(texts, isNotEmpty);
    for (final s in texts) {
      expect(hasEmoji(s), isFalse, reason: s);
    }
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('every lifeIndexKey resolves in $locale', (t) async {
      late AppLocalizations l;
      await t.pumpWidget(
        host(
          Builder(
            builder: (c) {
              l = AppLocalizations.of(c);
              return const SizedBox();
            },
          ),
          locale: locale,
        ),
      );
      for (final k in lifeIndexKeys) {
        expect(lifeIndexText(l, k), isNotEmpty, reason: k);
      }
    });
  }

  testWidgets('all cards render RTL at 360 px without overflow', (t) async {
    await t.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    for (final b in [london, threeDay]) {
      await t.pumpWidget(
        host(
          Column(children: allCards(b, settingsC)),
          locale: const Locale('ar'),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(
        Directionality.of(t.element(find.byType(DailyCard))),
        TextDirection.rtl,
      );
    }
  });

  Future<AppLocalizations> l10n(WidgetTester t, Locale locale) async {
    late AppLocalizations l;
    await t.pumpWidget(
      host(
        Builder(
          builder: (c) {
            l = AppLocalizations.of(c);
            return const SizedBox();
          },
        ),
        locale: locale,
      ),
    );
    return l;
  }

  testWidgets('wind direction and units come from l10n (ar)', (t) async {
    await t.pumpWidget(
      host(
        Column(
          children: [
            MetricCard.wind(london.current, WindUnit.kmh),
            MetricCard.pressure(1015),
            MetricCard.visibility(10),
            MetricCard.humidity(london.current, TempUnit.c),
          ],
        ),
        locale: const Locale('ar'),
      ),
    );
    expect(find.text('كم/س'), findsOneWidget);
    expect(find.text('مليبار'), findsOneWidget);
    expect(find.text('كم'), findsOneWidget);
    expect(find.text('٪'), findsOneWidget);
    // Fixture windDir is "E".
    expect(find.textContaining('شرق'), findsOneWidget);
    expect(find.textContaining('km/h'), findsNothing);
  });

  testWidgets('windDirText maps all 16 points, unknown stays raw', (t) async {
    final l = await l10n(t, const Locale('ar'));
    const points = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    final out = {for (final p in points) windDirText(l, p)};
    expect(out.length, 16);
    for (final p in points) {
      expect(windDirText(l, p), isNot(p));
    }
    expect(windDirText(l, 'XYZ'), 'XYZ');
    final en = await l10n(t, const Locale('en'));
    expect(windDirText(en, 'WSW'), 'WSW');
    expect(windUnitText(en, WindUnit.ms), 'm/s');
    expect(windUnitText(l, WindUnit.mph), 'ميل/س');
  });

  testWidgets('Arabic hourly labels and hero temp use ASCII digits', (t) async {
    await t.pumpWidget(
      host(
        Column(
          children: [
            CurrentHero(london, settingsC),
            HourlyCard(london.hourly, settingsC, toCityTime: london.toCityTime),
          ],
        ),
        locale: const Locale('ar'),
      ),
    );
    final heroTemp = find.descendant(
      of: find.byType(CurrentHero),
      matching: find.text('9'),
    );
    expect(heroTemp, findsOneWidget);
    final hourTexts = [
      for (final w in t.widgetList<Text>(
        find.descendant(
          of: find.byType(HourlyCard),
          matching: find.byType(Text),
        ),
      ))
        w.data ?? '',
    ];
    final second = london.toCityTime(london.hourly[1].time);
    expect(hourTexts, contains(second.hour.toString().padLeft(2, '0')));
    final nonAscii = RegExp(r'[٠-٩۰-۹]');
    for (final s in [...hourTexts, t.widget<Text>(heroTemp).data!]) {
      expect(nonAscii.hasMatch(s), isFalse, reason: s);
    }
  });

  testWidgets('HourlyCard survives 1.3x text scale at 360 px (ar)', (t) async {
    await t.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    for (final scale in [1.3, 2.0]) {
      await t.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 800),
            textScaler: TextScaler.linear(scale),
          ),
          child: host(
            HourlyCard(london.hourly, settingsC, toCityTime: london.toCityTime),
            locale: const Locale('ar'),
          ),
        ),
      );
      expect(t.takeException(), isNull, reason: 'scale $scale');
    }
  });

  DailyPoint flatDay(DailyPoint d, int offset) => DailyPoint(
    date: d.date.add(Duration(days: offset)),
    minC: 12,
    maxC: 12,
    uv: d.uv,
    chanceOfRain: d.chanceOfRain,
    condition: d.condition,
    sunrise: d.sunrise,
    sunset: d.sunset,
    moonPhase: d.moonPhase,
  );

  testWidgets('DailyCard handles identical min/max and a single day', (
    t,
  ) async {
    final base = london.daily.first;
    for (final days in [
      [for (var i = 0; i < 5; i++) flatDay(base, i)],
      [flatDay(base, 0)],
      [base],
    ]) {
      await t.pumpWidget(host(DailyCard(days, settingsC)));
      expect(t.takeException(), isNull);
      expect(find.byType(DailyRow), findsNWidgets(days.length));
      expect(find.byType(RangeBar), findsNWidgets(days.length));
      for (final e in t.elementList(find.byType(RangeBar))) {
        final segment = find.descendant(
          of: find.byWidget(e.widget),
          matching: find.byType(DecoratedBox),
        );
        expect(t.getSize(segment.last).width, greaterThan(0));
      }
    }
  });

  testWidgets('RTL keeps the number before its degree / unit', (t) async {
    await t.pumpWidget(
      host(
        Column(
          children: [
            CurrentHero(london, settingsC),
            MetricCard.wind(london.current, WindUnit.kmh),
          ],
        ),
        locale: const Locale('ar'),
      ),
    );
    final hero = find.byType(CurrentHero);
    final num = t.getRect(find.descendant(of: hero, matching: find.text('9')));
    final deg = t.getRect(find.descendant(of: hero, matching: find.text('°')));
    expect(num.left, lessThan(deg.left));
    final wind = find.byType(MetricCard);
    final value = t.getRect(
      find.descendant(
        of: wind,
        matching: find.text('${london.current.windKph.round()}'),
      ),
    );
    final unit = t.getRect(
      find.descendant(of: wind, matching: find.text('كم/س')),
    );
    expect(value.left, lessThan(unit.left));
  });

  testWidgets('Arabic labels: no letter spacing (letters stay joined)', (
    t,
  ) async {
    TextStyle labelStyle(String text) =>
        t.renderObject<RenderParagraph>(find.text(text)).text.style!;
    await t.pumpWidget(host(MetricCard.pressure(1015)));
    expect(labelStyle('PRESSURE').letterSpacing, greaterThan(0));
    await t.pumpWidget(
      host(
        Column(
          children: [
            MetricCard.pressure(1015),
            SunCard(london.daily.first, london.toCityTime(london.fetchedAt)),
          ],
        ),
        locale: const Locale('ar'),
      ),
    );
    final l = await AppLocalizations.delegate.load(const Locale('ar'));
    for (final text in [l.pressure, l.sunrise, l.sunset]) {
      expect(labelStyle(text).letterSpacing ?? 0, 0, reason: text);
    }
  });
}
