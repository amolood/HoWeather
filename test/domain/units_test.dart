import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/domain/models.dart';
import 'package:howeather/domain/units.dart';

void main() {
  test('convertTemp celsius to fahrenheit', () {
    expect(convertTemp(10, TempUnit.f), 50);
    expect(convertTemp(10, TempUnit.c), 10);
  });

  test('convertWind conversions', () {
    expect(convertWind(36, WindUnit.ms), 10);
    expect(convertWind(16.0934, WindUnit.mph), closeTo(10, 0.01));
    expect(convertWind(36, WindUnit.kmh), 36);
  });

  group('City', () {
    const c = City(
      id: '24.71,46.68',
      name: 'Riyadh',
      region: 'Ar Riyad',
      country: 'Saudi Arabia',
      lat: 24.71,
      lon: 46.68,
    );

    test('json round trip keeps equality and hashCode', () {
      final back = City.fromJson(c.toJson());
      expect(back, c);
      expect(back.hashCode, c.hashCode);
      expect(back.isCurrentLocation, false);
    });

    test('current location flag round trips and differs', () {
      const loc = City(
        id: 'loc',
        name: 'Riyadh',
        region: 'Ar Riyad',
        country: 'Saudi Arabia',
        lat: 24.71,
        lon: 46.68,
        isCurrentLocation: true,
      );
      expect(City.fromJson(loc.toJson()), loc);
      expect(loc == c, false);
    });

    test('query is lat,lon', () {
      expect(c.query, '24.71,46.68');
    });
  });
}
