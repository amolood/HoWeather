import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/data/prefs_store.dart';
import 'package:howeather/domain/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

City city(int i) => City(
  id: '$i.00,$i.00',
  name: 'City $i',
  region: 'R',
  country: 'C',
  lat: i.toDouble(),
  lon: i.toDouble(),
);

const loc = City(
  id: 'loc',
  name: 'Here',
  region: 'R',
  country: 'C',
  lat: 1.5,
  lon: 2.5,
  isCurrentLocation: true,
);

Future<PrefsStore> store([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return PrefsStore(await SharedPreferences.getInstance());
}

void main() {
  group('settings', () {
    test('defaults by locale', () async {
      final s = await store();
      final us = s.loadSettings(const Locale('en', 'US'));
      expect(us.temp, TempUnit.f);
      expect(us.refresh, const Duration(hours: 1));
      expect(us.wind, WindUnit.kmh);
      expect(us.theme, ThemePref.system);
      expect(s.loadSettings(const Locale('ar', 'SD')).temp, TempUnit.c);
      expect(s.loadSettings(const Locale('en')).temp, TempUnit.c);
      for (final c in ['LR', 'MM', 'BS', 'BZ', 'KY', 'PW']) {
        expect(s.loadSettings(Locale('en', c)).temp, TempUnit.f);
      }
    });

    test('round trip, incl. manual refresh', () async {
      final s = await store();
      const v = Settings(
        temp: TempUnit.f,
        wind: WindUnit.ms,
        refresh: Duration.zero,
        theme: ThemePref.dark,
      );
      await s.saveSettings(v);
      final back = s.loadSettings(const Locale('ar', 'SD'));
      expect(back, v);
      expect(back.hashCode, v.hashCode);
    });

    test('unknown persisted values fall back to defaults', () async {
      final s = await store({
        'temp': 'kelvin',
        'wind': 'knots',
        'refresh_min': 7,
        'theme': 'neon',
      });
      final l = s.loadSettings(const Locale('en', 'US'));
      expect(l.temp, TempUnit.f);
      expect(l.wind, WindUnit.kmh);
      expect(l.refresh, const Duration(hours: 1));
      expect(l.theme, ThemePref.system);
    });

    test('copyWith', () {
      const a = Settings(
        temp: TempUnit.c,
        wind: WindUnit.kmh,
        refresh: Duration(hours: 1),
        theme: ThemePref.system,
      );
      final b = a.copyWith(temp: TempUnit.f, refresh: const Duration(hours: 6));
      expect(b.temp, TempUnit.f);
      expect(b.refresh, const Duration(hours: 6));
      expect(b.wind, a.wind);
      expect(a.copyWith(), a);
    });
  });

  group('cities persistence', () {
    test('round trip', () async {
      final s = await store();
      expect(s.loadCities(), isEmpty);
      await s.saveCities([loc, city(2)]);
      expect(s.loadCities(), [loc, city(2)]);
    });

    test('corrupt json yields empty list', () async {
      expect((await store({'cities': 'not json'})).loadCities(), isEmpty);
      expect((await store({'cities': '{"a":1}'})).loadCities(), isEmpty);
      expect((await store({'cities': '[{"id":1}]'})).loadCities(), isEmpty);
    });
  });

  group('list operations', () {
    test('add appends; duplicate is a no-op', () {
      final a = addCity([city(1)], city(2));
      expect(a, [city(1), city(2)]);
      expect(addCity(a, city(2)), a);
    });

    test('11th city throws, cap counts loc', () {
      final ten = [for (var i = 1; i <= 10; i++) city(i)];
      expect(() => addCity(ten, city(11)), throwsA(isA<CityLimitException>()));
      final nine = [loc, for (var i = 1; i <= 9; i++) city(i)];
      expect(() => addCity(nine, city(11)), throwsA(isA<CityLimitException>()));
    });

    test('duplicate at the cap is a no-op, not a throw', () {
      final ten = [for (var i = 1; i <= 10; i++) city(i)];
      expect(addCity(ten, city(3)), ten);
    });

    test('adding loc inserts at 0 or replaces in place', () {
      expect(addCity([city(1)], loc), [loc, city(1)]);
      const loc2 = City(
        id: 'loc',
        name: 'There',
        region: 'R',
        country: 'C',
        lat: 9,
        lon: 9,
        isCurrentLocation: true,
      );
      expect(addCity([loc, city(1)], loc2), [loc2, city(1)]);
      final ten = [loc, for (var i = 1; i <= 9; i++) city(i)];
      expect(addCity(ten, loc2).length, 10);
    });

    test('remove by id (incl. loc), unknown id no-op', () {
      expect(removeCity([loc, city(1)], 'loc'), [city(1)]);
      expect(removeCity([city(1), city(2)], '1.00,1.00'), [city(2)]);
      expect(removeCity([city(1)], 'zzz'), [city(1)]);
    });

    test('moveCity reorders without loc', () {
      final l = [city(1), city(2), city(3)];
      expect(moveCity(l, 0, 2), [city(2), city(3), city(1)]);
      expect(moveCity(l, 2, 0), [city(3), city(1), city(2)]);
      expect(l, [city(1), city(2), city(3)]);
    });

    test('moveCity cannot move loc or go above it', () {
      final l = [loc, city(1), city(2)];
      expect(moveCity(l, 0, 2), l);
      expect(moveCity(l, 2, 0), [loc, city(2), city(1)]);
      expect(moveCity(l, 1, 0), l);
    });

    test('moveCity ignores out-of-range indices', () {
      final l = [city(1), city(2)];
      expect(moveCity(l, 5, 0), l);
      expect(moveCity(l, 0, 9), [city(2), city(1)]);
    });
  });
}
