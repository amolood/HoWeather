import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/data/weather_mapper.dart';
import 'package:howeather/domain/models.dart';
import 'package:howeather/domain/weather_view.dart';

void main() {
  // London (GMT): hourly starts at 2026-11-09 17:00, daily at 2026-11-09.
  final b = mapForecast(
    jsonDecode(File('test/fixtures/forecast_london.json').readAsStringSync())
        as Map<String, dynamic>,
    fetchedAt: DateTime.utc(2026, 11, 9, 17, 40),
  );
  final firstHour = b.hourly.first.time;

  test('fresh bundle: everything visible, Now and Today', () {
    final v = visibleWindow(b, firstHour.add(const Duration(minutes: 30)));
    expect(v.hours.length, b.hourly.length);
    expect(v.days.length, b.daily.length);
    expect(v.firstHourIsNow, isTrue);
    expect(v.firstDayIsToday, isTrue);
  });

  test('5 hours stale: past hours dropped, current hour kept as Now', () {
    final now = firstHour.add(const Duration(hours: 5, minutes: 10));
    final v = visibleWindow(b, now);
    expect(v.hours.length, b.hourly.length - 5);
    expect(v.hours.first.time, b.hourly[5].time);
    expect(v.firstHourIsNow, isTrue);
    expect(v.days.first.date, b.daily.first.date);
    expect(v.firstDayIsToday, isTrue);
  });

  test('1 day stale: yesterday dropped, first day is Today', () {
    final v = visibleWindow(b, firstHour.add(const Duration(days: 1)));
    expect(v.hours, isEmpty);
    expect(v.firstHourIsNow, isFalse);
    expect(v.days.length, b.daily.length - 1);
    expect(v.days.first.date, DateTime.utc(2026, 11, 10));
    expect(v.firstDayIsToday, isTrue);
  });

  test('clock behind the data: nothing dropped, no Now/Today labels', () {
    final v = visibleWindow(b, DateTime.utc(2026, 11, 8, 12));
    expect(v.hours.length, b.hourly.length);
    expect(v.days.length, b.daily.length);
    expect(v.firstHourIsNow, isFalse);
    expect(v.firstDayIsToday, isFalse);
  });

  test('uses the city clock, not UTC, for the day boundary', () {
    final plus3 = WeatherBundle(
      cityName: b.cityName,
      region: b.region,
      country: b.country,
      tzId: b.tzId,
      lat: b.lat,
      lon: b.lon,
      utcOffset: const Duration(hours: 3),
      current: b.current,
      hourly: b.hourly,
      daily: b.daily,
      alerts: b.alerts,
      fetchedAt: b.fetchedAt,
    );
    // 22:00 UTC on the 9th is 01:00 on the 10th in a UTC+3 city.
    final v = visibleWindow(plus3, DateTime.utc(2026, 11, 9, 22));
    expect(v.days.first.date, DateTime.utc(2026, 11, 10));
    expect(v.firstDayIsToday, isTrue);
    expect(
      visibleWindow(b, DateTime.utc(2026, 11, 9, 22)).days.first.date,
      DateTime.utc(2026, 11, 9),
    );
  });
}
