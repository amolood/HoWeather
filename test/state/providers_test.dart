import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/data/location_service.dart';
import 'package:howeather/data/prefs_store.dart';
import 'package:howeather/data/weather_api.dart';
import 'package:howeather/data/weather_cache.dart';
import 'package:howeather/data/weather_mapper.dart';
import 'package:howeather/data/weather_repository.dart';
import 'package:howeather/domain/models.dart';
import 'package:howeather/state/providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApi extends Mock implements WeatherApi {}

class MockRepo extends Mock implements WeatherRepository {}

class FakeLocation implements LocationService {
  final LocationOutcome outcome;
  FakeLocation(this.outcome);
  @override
  Future<LocationOutcome> current() async => outcome;
  @override
  Future<void> openSettings() async {}
}

/// Location that resolves only when the test completes [result].
class SlowLocation implements LocationService {
  final result = Completer<LocationOutcome>();
  @override
  Future<LocationOutcome> current() => result.future;
  @override
  Future<void> openSettings() async {}
}

class MemoryCache implements WeatherCache {
  final Map<String, CachedWeather> store = {};
  @override
  Future<CachedWeather?> read(String cityId) async => store[cityId];
  @override
  Future<void> write(String id, Map<String, dynamic> raw, DateTime at) async {
    store[id] = CachedWeather(raw: raw, fetchedAt: at);
  }
}

City city(String id, String name) =>
    City(id: id, name: name, region: '', country: '', lat: 1, lon: 2);

final mecca = city('21.42,39.83', 'Mecca');
final london = city('51.52,-0.11', 'London');

Map<String, dynamic> raw() =>
    jsonDecode(File('test/fixtures/forecast_london.json').readAsStringSync())
        as Map<String, dynamic>;

Future<ProviderContainer> makeContainer({
  List<City> saved = const [],
  LocationOutcome outcome = const LocationDenied(),
  LocationService? location,
  WeatherRepository? repo,
  Locale locale = const Locale('en', 'GB'),
  Map<String, Object> extraPrefs = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    if (saved.isNotEmpty)
      'cities': jsonEncode([for (final c in saved) c.toJson()]),
    ...extraPrefs,
  });
  final prefs = await SharedPreferences.getInstance();
  final r = repo ?? MockRepo();
  if (repo == null) {
    when(() => r.search(any())).thenAnswer((_) async => [london]);
  }
  final c = ProviderContainer(
    overrides: [
      prefsStoreProvider.overrideWithValue(PrefsStore(prefs)),
      weatherRepositoryProvider.overrideWithValue(r),
      locationServiceProvider.overrideWithValue(
        location ?? FakeLocation(outcome),
      ),
      localeProvider.overrideWith(() => LocaleNotifier(locale)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(() {
    registerFallbackValue(mecca);
    registerFallbackValue(Duration.zero);
  });

  group('citiesProvider', () {
    test('saved list plus current location at 0 when found', () async {
      final c = await makeContainer(
        saved: [mecca],
        outcome: const LocationFound(51.5, -0.1),
      );
      await c.read(citiesProvider.future);
      await pumpEventQueue();
      final list = c.read(citiesProvider).value!;
      expect(list.map((x) => x.id), ['loc', mecca.id]);
      expect(list.first.name, 'London');
    });

    test('replaces a stale saved loc city', () async {
      final stale = City(
        id: 'loc',
        name: 'Old',
        region: '',
        country: '',
        lat: 0,
        lon: 0,
        isCurrentLocation: true,
      );
      final c = await makeContainer(
        saved: [stale, mecca],
        outcome: const LocationFound(51.5, -0.1),
      );
      await c.read(citiesProvider.future);
      await pumpEventQueue();
      final list = c.read(citiesProvider).value!;
      expect(list.map((x) => x.id), ['loc', mecca.id]);
      expect(list.first.name, 'London');
    });

    test('only saved list when location denied', () async {
      final c = await makeContainer(saved: [mecca]);
      expect(await c.read(citiesProvider.future), [
        isA<City>().having((x) => x.id, 'id', mecca.id),
      ]);
    });

    test('add/remove/move persist and update state', () async {
      final c = await makeContainer(saved: [mecca]);
      await c.read(citiesProvider.future);
      final n = c.read(citiesProvider.notifier);
      await n.add(london);
      expect(c.read(citiesProvider).value!.map((x) => x.id), [
        mecca.id,
        london.id,
      ]);
      await n.move(1, 0);
      expect(c.read(citiesProvider).value!.first.id, london.id);
      expect(c.read(prefsStoreProvider).loadCities().first.id, london.id);
      await n.remove(london.id);
      expect(c.read(citiesProvider).value!.map((x) => x.id), [mecca.id]);
      expect(c.read(prefsStoreProvider).loadCities().length, 1);
    });

    test('add rethrows CityLimitException at 10 cities', () async {
      final full = [for (var i = 0; i < maxCities; i++) city('c$i', 'C$i')];
      final c = await makeContainer(saved: full);
      await c.read(citiesProvider.future);
      expect(
        () => c.read(citiesProvider.notifier).add(london),
        throwsA(isA<CityLimitException>()),
      );
    });

    test('refreshLocation inserts the current city', () async {
      final c2 = await makeContainer(
        saved: [mecca],
        outcome: const LocationFound(51.5, -0.1),
      );
      await c2.read(citiesProvider.future);
      final outcome = await c2.read(citiesProvider.notifier).refreshLocation();
      expect(outcome, isA<LocationFound>());
      expect(c2.read(citiesProvider).value!.map((x) => x.id), [
        'loc',
        mecca.id,
      ]);
    });

    test('refreshLocation reports denial and changes nothing', () async {
      final c = await makeContainer(saved: [mecca]);
      await c.read(citiesProvider.future);
      final outcome = await c.read(citiesProvider.notifier).refreshLocation();
      expect(outcome, isA<LocationDenied>());
      expect(c.read(citiesProvider).value!.map((x) => x.id), [mecca.id]);
    });

    test('10 saved + location found keeps the 10, never overwrites', () async {
      final full = [for (var i = 0; i < maxCities; i++) city('c$i', 'C$i')];
      final c = await makeContainer(
        saved: full,
        outcome: const LocationFound(51.5, -0.1),
      );
      await c.read(citiesProvider.future);
      await pumpEventQueue();
      final store = c.read(prefsStoreProvider);
      expect(c.read(citiesProvider).hasError, isFalse);
      expect(c.read(citiesProvider).value, full);
      expect(store.loadCities(), full);
      await expectLater(
        c.read(citiesProvider.notifier).add(london),
        throwsA(isA<CityLimitException>()),
      );
      expect(store.loadCities(), full);
      expect(c.read(citiesProvider).value, full);
    });

    test('saved cities are available before location resolves', () async {
      final slow = SlowLocation();
      final c = await makeContainer(saved: [mecca], location: slow);
      final list = await c.read(citiesProvider.future);
      expect(list.map((x) => x.id), [mecca.id]);
      slow.result.complete(const LocationFound(51.5, -0.1));
      await pumpEventQueue();
      expect(c.read(citiesProvider).value!.map((x) => x.id), ['loc', mecca.id]);
      expect(c.read(prefsStoreProvider).loadCities().first.id, 'loc');
    });

    test('location arriving late keeps cities added meanwhile', () async {
      final slow = SlowLocation();
      final c = await makeContainer(saved: [mecca], location: slow);
      await c.read(citiesProvider.future);
      await c.read(citiesProvider.notifier).add(london);
      slow.result.complete(const LocationFound(51.5, -0.1));
      await pumpEventQueue();
      expect(c.read(citiesProvider).value!.map((x) => x.id), [
        'loc',
        mecca.id,
        london.id,
      ]);
    });
  });

  group('settingsProvider', () {
    test('update persists and changes state', () async {
      final c = await makeContainer();
      final s = c.read(settingsProvider);
      await c
          .read(settingsProvider.notifier)
          .update(s.copyWith(temp: TempUnit.f));
      expect(c.read(settingsProvider).temp, TempUnit.f);
      expect(
        c.read(prefsStoreProvider).loadSettings(const Locale('en')).temp,
        TempUnit.f,
      );
    });
  });

  group('weatherProvider', () {
    test('changing TempUnit does not call the api again', () async {
      final api = MockApi();
      when(() => api.forecast(any(), lang: any(named: 'lang')))
          .thenAnswer((_) async => raw());
      final c = await makeContainer(
        repo: WeatherRepository(api, MemoryCache()),
      );
      await c.read(weatherProvider(mecca).future);
      final s = c.read(settingsProvider);
      await c
          .read(settingsProvider.notifier)
          .update(s.copyWith(temp: TempUnit.f));
      await c.read(weatherProvider(mecca).future);
      verify(() => api.forecast(any(), lang: any(named: 'lang'))).called(1);
    });

    WeatherResult result() =>
        WeatherResult(mapForecast(raw(), fetchedAt: DateTime.utc(2026, 1, 1)));

    test('passes lang and default 1h maxAge; ar locale gives ar', () async {
      final repo = MockRepo();
      when(
        () => repo.load(
          any(),
          lang: any(named: 'lang'),
          maxAge: any(named: 'maxAge'),
          force: any(named: 'force'),
        ),
      ).thenAnswer((_) async => result());
      final c = await makeContainer(
        repo: repo,
        locale: const Locale('ar', 'SA'),
      );
      await c.read(weatherProvider(mecca).future);
      verify(
        () => repo.load(
          mecca,
          lang: 'ar',
          maxAge: const Duration(hours: 1),
          force: false,
        ),
      ).called(1);
    });

    test('manual refresh gives maxAge of 100 days', () async {
      final repo = MockRepo();
      when(
        () => repo.load(
          any(),
          lang: any(named: 'lang'),
          maxAge: any(named: 'maxAge'),
          force: any(named: 'force'),
        ),
      ).thenAnswer((_) async => result());
      final c = await makeContainer(repo: repo, extraPrefs: {'refresh_min': 0});
      await c.read(weatherProvider(mecca).future);
      verify(
        () => repo.load(
          mecca,
          lang: 'en',
          maxAge: const Duration(days: 100),
          force: false,
        ),
      ).called(1);
    });

    test('refresh() forces and keeps previous value while loading', () async {
      final repo = MockRepo();
      when(
        () => repo.load(
          any(),
          lang: any(named: 'lang'),
          maxAge: any(named: 'maxAge'),
          force: any(named: 'force'),
        ),
      ).thenAnswer((_) async => result());
      final c = await makeContainer(repo: repo);
      await c.read(weatherProvider(mecca).future);
      final seen = <AsyncValue<WeatherResult>>[];
      c.listen(weatherProvider(mecca), (_, n) => seen.add(n));
      await c.read(weatherProvider(mecca).notifier).refresh();
      expect(seen.first.isLoading, isTrue);
      expect(seen.first.hasValue, isTrue);
      verify(
        () => repo.load(
          mecca,
          lang: 'en',
          maxAge: any(named: 'maxAge'),
          force: true,
        ),
      ).called(1);
    });
  });

  test('pageIndexProvider defaults to 0 and can be set', () async {
    final c = await makeContainer();
    expect(c.read(pageIndexProvider), 0);
    c.read(pageIndexProvider.notifier).set(2);
    expect(c.read(pageIndexProvider), 2);
  });
}
