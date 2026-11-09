import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/data/weather_mapper.dart';

Map<String, dynamic> load(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final fetchedAt = DateTime.utc(2026, 11, 9, 17, 40);

  group('mapForecast (London, 14 days)', () {
    final json = load('forecast_london.json');
    final bundle = mapForecast(json, fetchedAt: fetchedAt);

    test('maps location and days', () {
      expect(bundle.cityName, 'London');
      expect(bundle.daily.length, 14);
      expect(bundle.fetchedAt, fetchedAt);
      expect(bundle.tzId, json['location']['tz_id']);
    });

    test('maps location coordinates', () {
      expect(bundle.lat, 51.5171);
      expect(bundle.lon, -0.1062);
    });

    test('hourly is the next 24 hours from the current hour', () {
      final updated = json['current']['last_updated_epoch'] as int;
      expect(bundle.hourly.length, 24);
      final first = bundle.hourly.first.time;
      final firstSec = first.millisecondsSinceEpoch ~/ 1000;
      expect(firstSec <= updated, isTrue);
      expect(updated - firstSec < 3600, isTrue);
      for (var i = 1; i < 24; i++) {
        expect(
          bundle.hourly[i].time.difference(bundle.hourly[i - 1].time),
          const Duration(hours: 1),
        );
      }
      // Spans into day 2.
      expect(bundle.hourly.last.time.day != first.day, isTrue);
    });

    test('current and air quality', () {
      expect(
        bundle.current.condition.code,
        json['current']['condition']['code'],
      );
      expect(
        bundle.current.air!.epaIndex,
        json['current']['air_quality']['us-epa-index'],
      );
      expect(
        bundle.current.updatedAt.millisecondsSinceEpoch ~/ 1000,
        json['current']['last_updated_epoch'],
      );
    });

    test('sunrise/sunset are 24h HH:mm', () {
      expect(bundle.daily.first.sunrise, '07:08');
      expect(bundle.daily.first.sunset, '16:20');
    });

    test('empty alerts', () {
      expect(bundle.alerts, isEmpty);
    });
  });

  test('utcOffset and toCityTime (London, GMT)', () {
    final json = load('forecast_london.json');
    final bundle = mapForecast(json, fetchedAt: fetchedAt);
    expect(bundle.utcOffset, Duration.zero);
    final firstEpoch = bundle.hourly.first.time.millisecondsSinceEpoch ~/ 1000;
    final match = [
      for (final d in json['forecast']['forecastday']) ...d['hour'] as List,
    ].firstWhere((h) => h['time_epoch'] == firstEpoch);
    final hourStr = (match['time'] as String).split(' ')[1].split(':')[0];
    expect(
      bundle.toCityTime(bundle.hourly.first.time).hour,
      int.parse(hourStr),
    );
    expect(bundle.daily.first.date.isUtc, isTrue);
    expect(bundle.daily.first.date, DateTime.utc(2026, 11, 9));
  });

  test('unpadded hour in localtime is parsed', () {
    final json = load('forecast_london.json');
    json['location']['localtime'] = '2026-11-09 9:05';
    json['location']['localtime_epoch'] =
        DateTime.utc(2026, 11, 9, 9, 5).millisecondsSinceEpoch ~/ 1000;
    final bundle = mapForecast(json, fetchedAt: fetchedAt);
    expect(bundle.utcOffset, Duration.zero);
  });

  test('half-hour offset (+5:30) is detected and hourly start is correct', () {
    final json = load('forecast_london.json');
    json['location']['localtime'] = '2026-11-09 23:01';
    final bundle = mapForecast(json, fetchedAt: fetchedAt);
    expect(bundle.utcOffset, const Duration(hours: 5, minutes: 30));
    final updated = json['current']['last_updated_epoch'] as int;
    final first = bundle.hourly.first.time.millisecondsSinceEpoch ~/ 1000;
    expect(first <= updated, isTrue);
    expect(updated < first + 3600, isTrue);
    expect(bundle.toCityTime(bundle.hourly.first.time).hour, 22);
  });

  test('structural failure becomes WeatherApiException without code', () {
    for (final bad in [
      <String, dynamic>{'foo': 1},
      <String, dynamic>{'location': 5, 'current': {}},
    ]) {
      expect(
        () => mapForecast(bad, fetchedAt: fetchedAt),
        throwsA(
          isA<WeatherApiException>()
              .having((e) => e.code, 'code', isNull)
              .having((e) => e.message, 'message', 'Unexpected response'),
        ),
      );
    }
    expect(
      () => mapForecast({
        'error': {'code': 1006, 'message': 'x'},
      }, fetchedAt: fetchedAt),
      throwsA(isA<WeatherApiException>().having((e) => e.code, 'code', 1006)),
    );
  });

  test('3-day, no AQI fixture', () {
    final bundle = mapForecast(
      load('forecast_3day_noaqi.json'),
      fetchedAt: fetchedAt,
    );
    expect(bundle.daily.length, 3);
    expect(bundle.current.air, isNull);
  });

  test('polar astro and alerts are handled', () {
    final json = load('forecast_3day_noaqi.json');
    final astro = json['forecast']['forecastday'][0]['astro'] as Map;
    astro['sunrise'] = 'No sunrise';
    astro['sunset'] = 'No sunset';
    json['alerts'] = {
      'alert': [
        {'headline': 'H', 'severity': 'Moderate', 'event': 'Wind', 'desc': 'D'},
      ],
    };
    final bundle = mapForecast(json, fetchedAt: fetchedAt);
    expect(bundle.daily.first.sunrise, '--:--');
    expect(bundle.daily.first.sunset, '--:--');
    expect(bundle.alerts.single.headline, 'H');
    expect(bundle.alerts.single.event, 'Wind');
  });

  test('12 AM / 12 PM conversion', () {
    final json = load('forecast_3day_noaqi.json');
    final astro = json['forecast']['forecastday'][0]['astro'] as Map;
    astro['sunrise'] = '12:05 AM';
    astro['sunset'] = '12:30 PM';
    final bundle = mapForecast(json, fetchedAt: fetchedAt);
    expect(bundle.daily.first.sunrise, '00:05');
    expect(bundle.daily.first.sunset, '12:30');
  });

  test('throwIfApiError throws with code', () {
    expect(
      () => throwIfApiError({
        'error': {'code': 2006, 'message': 'API key is invalid.'},
      }),
      throwsA(
        isA<WeatherApiException>()
            .having((e) => e.code, 'code', 2006)
            .having((e) => e.message, 'message', 'API key is invalid.'),
      ),
    );
    expect(() => throwIfApiError({'location': {}}), returnsNormally);
  });

  group('mapSearch', () {
    test('maps entries to cities', () {
      final cities = mapSearch([
        {
          'id': 2251954,
          'name': 'Khartoum',
          'region': 'Al Khartum',
          'country': 'Sudan',
          'lat': 15.59,
          'lon': 32.53,
        },
      ]);
      expect(cities.length, 1);
      expect(cities.first.id, '15.59,32.53');
      expect(cities.first.name, 'Khartoum');
      expect(cities.first.region, 'Al Khartum');
    });

    test('missing region becomes empty', () {
      final cities = mapSearch([
        {'name': 'X', 'country': 'Y', 'lat': 1, 'lon': 2},
      ]);
      expect(cities.first.region, '');
      expect(cities.first.id, '1.00,2.00');
    });
  });
}
