import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/domain/life_index.dart';
import 'package:howeather/domain/models.dart';

const _cond = Condition(code: 1000, text: 'Sunny', isDay: true);

CurrentWeather _now({
  double feels = 18,
  double wind = 5,
  double uv = 1,
  int? epa,
  bool noAir = false,
}) => CurrentWeather(
  tempC: feels,
  feelsLikeC: feels,
  windKph: wind,
  gustKph: wind,
  pressureMb: 1013,
  visKm: 10,
  uv: uv,
  dewPointC: 5,
  humidity: 50,
  windDegree: 0,
  cloud: 0,
  windDir: 'N',
  condition: _cond,
  air: noAir ? null : AirQuality(epaIndex: epa),
  updatedAt: DateTime.utc(2026, 11, 9),
);

DailyPoint _day({int rain = 0, double uv = 5}) => DailyPoint(
  date: DateTime.utc(2026, 11, 9),
  minC: 10,
  maxC: 20,
  uv: uv,
  chanceOfRain: rain,
  condition: _cond,
  sunrise: '06:00',
  sunset: '18:00',
  moonPhase: 'Full Moon',
);

LifeIndex _get(List<LifeIndex> l, LifeKind k) =>
    l.firstWhere((e) => e.kind == k);

String _key(LifeKind k, CurrentWeather n, DailyPoint t, [DailyPoint? tm]) =>
    _get(deriveLifeIndices(n, t, tm), k).key;

void main() {
  test('always 6 items in LifeKind order, keys within lifeIndexKeys', () {
    final l = deriveLifeIndices(_now(), _day(), null);
    expect(l.map((e) => e.kind).toList(), LifeKind.values);
    expect(l.length, 6);
    expect(lifeIndexKeys.toSet().length, lifeIndexKeys.length);
    for (final e in l) {
      expect(lifeIndexKeys, contains(e.key));
    }
  });

  group('dress', () {
    test('thresholds', () {
      expect(_key(LifeKind.dress, _now(feels: 9.9), _day()), 'dressWarm');
      expect(_key(LifeKind.dress, _now(feels: 10), _day()), 'dressLight');
      expect(_key(LifeKind.dress, _now(feels: 22), _day()), 'dressLight');
      expect(_key(LifeKind.dress, _now(feels: 22.1), _day()), 'dressCool');
    });
  });

  group('carWash', () {
    test('today rain threshold', () {
      expect(_key(LifeKind.carWash, _now(), _day(rain: 39)), 'carWashGood');
      final l = deriveLifeIndices(_now(), _day(rain: 40), null);
      expect(_get(l, LifeKind.carWash).key, 'carWashPoor');
      expect(_get(l, LifeKind.carWash).level, LifeLevel.poor);
    });
    test('tomorrow rain counts; null tomorrow uses today only', () {
      expect(
        _key(LifeKind.carWash, _now(), _day(), _day(rain: 40)),
        'carWashPoor',
      );
      expect(
        _key(LifeKind.carWash, _now(), _day(), _day(rain: 39)),
        'carWashGood',
      );
      expect(_key(LifeKind.carWash, _now(), _day()), 'carWashGood');
    });
  });

  group('sport', () {
    test('rain', () {
      expect(_key(LifeKind.sport, _now(), _day(rain: 49)), 'sportIdeal');
      expect(_key(LifeKind.sport, _now(), _day(rain: 50)), 'sportPoor');
    });
    test('feels-like', () {
      expect(_key(LifeKind.sport, _now(feels: 35), _day()), 'sportIdeal');
      expect(_key(LifeKind.sport, _now(feels: 35.1), _day()), 'sportPoor');
      expect(_key(LifeKind.sport, _now(feels: 0), _day()), 'sportIdeal');
      expect(_key(LifeKind.sport, _now(feels: -0.1), _day()), 'sportPoor');
    });
    test('epa', () {
      expect(_key(LifeKind.sport, _now(epa: 3), _day()), 'sportIdeal');
      expect(_key(LifeKind.sport, _now(epa: 4), _day()), 'sportPoor');
    });
    test('null air ignores AQI', () {
      expect(_key(LifeKind.sport, _now(noAir: true), _day()), 'sportIdeal');
      expect(_key(LifeKind.sport, _now(), _day()), 'sportIdeal');
    });
  });

  group('umbrella', () {
    test('threshold', () {
      expect(_key(LifeKind.umbrella, _now(), _day(rain: 39)), 'umbrellaNo');
      expect(_key(LifeKind.umbrella, _now(), _day(rain: 40)), 'umbrellaYes');
    });
  });

  group('sunCream', () {
    test('thresholds', () {
      expect(_key(LifeKind.sunCream, _now(), _day(uv: 2.9)), 'uvLow');
      expect(_key(LifeKind.sunCream, _now(), _day(uv: 3)), 'uvModerate');
      expect(_key(LifeKind.sunCream, _now(), _day(uv: 6)), 'uvModerate');
      final l = deriveLifeIndices(_now(), _day(uv: 7), null);
      expect(_get(l, LifeKind.sunCream).key, 'uvHigh');
      expect(_get(l, LifeKind.sunCream).level, LifeLevel.poor);
    });
  });

  test('sunCream uses the day forecast UV, not current UV (night)', () {
    expect(_key(LifeKind.sunCream, _now(uv: 0), _day(uv: 7)), 'uvHigh');
  });

  group('allergy', () {
    test('epa', () {
      expect(_key(LifeKind.allergy, _now(epa: 2), _day()), 'allergyLow');
      expect(_key(LifeKind.allergy, _now(epa: 3), _day()), 'allergyModerate');
      expect(_key(LifeKind.allergy, _now(epa: 4), _day()), 'allergyHigh');
    });
    test('wind', () {
      expect(_key(LifeKind.allergy, _now(wind: 24.9), _day()), 'allergyLow');
      expect(_key(LifeKind.allergy, _now(wind: 25), _day()), 'allergyModerate');
    });
    test('null air ignores AQI', () {
      expect(_key(LifeKind.allergy, _now(noAir: true), _day()), 'allergyLow');
      expect(
        _key(LifeKind.allergy, _now(noAir: true, wind: 30), _day()),
        'allergyModerate',
      );
    });
  });
}
