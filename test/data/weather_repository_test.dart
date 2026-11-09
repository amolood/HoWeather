import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/config.dart';
import 'package:howeather/data/weather_api.dart';
import 'package:howeather/data/weather_cache.dart';
import 'package:howeather/data/weather_mapper.dart';
import 'package:howeather/data/weather_repository.dart';
import 'package:howeather/domain/models.dart';
import 'package:mocktail/mocktail.dart';

class MockApi extends Mock implements WeatherApi {}

class MemoryCache implements WeatherCache {
  final Map<String, CachedWeather> store = {};
  int writes = 0;
  @override
  Future<CachedWeather?> read(String cityId) async => store[cityId];
  @override
  Future<void> write(
    String cityId,
    Map<String, dynamic> raw,
    DateTime fetchedAt,
  ) async {
    writes++;
    store[cityId] = CachedWeather(raw: raw, fetchedAt: fetchedAt);
  }
}

class ThrowingWriteCache extends MemoryCache {
  @override
  Future<void> write(String id, Map<String, dynamic> raw, DateTime at) =>
      throw const FileSystemException('disk full');
}

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Dio adapter that returns a canned response or throws a canned error.
class FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) handler;
  FakeAdapter(this.handler);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

WeatherApi apiWith(ResponseBody Function(RequestOptions) h) {
  final dio = Dio()..httpClientAdapter = FakeAdapter(h);
  return WeatherApi(dio, key: 'k');
}

void main() {
  const city = City(
    id: '51.52,-0.11',
    name: 'London',
    region: '',
    country: 'UK',
    lat: 51.52,
    lon: -0.11,
  );
  final raw = fixture('forecast_london.json');
  final now = DateTime.utc(2026, 11, 9, 12);
  const maxAge = Duration(minutes: 60);

  group('WeatherRepository.load', () {
    late MockApi api;
    late MemoryCache cache;
    late WeatherRepository repo;
    setUp(() {
      api = MockApi();
      cache = MemoryCache();
      repo = WeatherRepository(api, cache, clock: () => now);
    });

    test('fresh cache -> api never called', () async {
      cache.store['${city.id}_en'] = CachedWeather(
        raw: raw,
        fetchedAt: now.subtract(const Duration(minutes: 10)),
      );
      final r = await repo.load(city, lang: 'en', maxAge: maxAge);
      expect(r.isStale, false);
      expect(r.error, isNull);
      expect(r.bundle.cityName, 'London');
      verifyNever(() => api.forecast(any(), lang: any(named: 'lang')));
    });

    test('stale cache + api ok -> fetched once, cache written', () async {
      cache.store['${city.id}_en'] = CachedWeather(
        raw: raw,
        fetchedAt: now.subtract(const Duration(hours: 2)),
      );
      when(() => api.forecast(any(), lang: any(named: 'lang')))
          .thenAnswer((_) async => raw);
      final r = await repo.load(city, lang: 'en', maxAge: maxAge);
      verify(() => api.forecast(city.query, lang: 'en')).called(1);
      expect(cache.writes, 1);
      expect(cache.store['${city.id}_en']!.fetchedAt, now);
      expect(r.isStale, false);
      expect(r.bundle.fetchedAt, now);
    });

    test('api throws + cache -> stale result with error', () async {
      cache.store['${city.id}_en'] = CachedWeather(
        raw: raw,
        fetchedAt: now.subtract(const Duration(hours: 2)),
      );
      when(() => api.forecast(any(), lang: any(named: 'lang')))
          .thenThrow(const WeatherApiException(null, 'offline'));
      final r = await repo.load(city, lang: 'en', maxAge: maxAge);
      expect(r.isStale, true);
      expect(r.error, isNotNull);
      expect(r.error!.message, 'offline');
      expect(r.bundle.cityName, 'London');
    });

    test('api throws + no cache -> throws WeatherApiException', () async {
      when(() => api.forecast(any(), lang: any(named: 'lang')))
          .thenThrow(const WeatherApiException(2007, 'quota'));
      expect(
        repo.load(city, lang: 'en', maxAge: maxAge),
        throwsA(isA<WeatherApiException>().having((e) => e.code, 'code', 2007)),
      );
    });

    test('force with fresh cache -> api called', () async {
      cache.store['${city.id}_en'] = CachedWeather(raw: raw, fetchedAt: now);
      when(() => api.forecast(any(), lang: any(named: 'lang')))
          .thenAnswer((_) async => raw);
      await repo.load(city, lang: 'en', maxAge: maxAge, force: true);
      verify(() => api.forecast(city.query, lang: 'en')).called(1);
    });

    test('cache is keyed by language', () async {
      cache.store['${city.id}_en'] = CachedWeather(raw: raw, fetchedAt: now);
      when(() => api.forecast(any(), lang: any(named: 'lang')))
          .thenAnswer((_) async => raw);
      await repo.load(city, lang: 'ar', maxAge: maxAge);
      verify(() => api.forecast(city.query, lang: 'ar')).called(1);
      expect(cache.store['${city.id}_ar']!.fetchedAt, now);
      await repo.load(city, lang: 'en', maxAge: maxAge);
      verifyNever(() => api.forecast(any(), lang: 'en'));
    });

    test('cache fetched in the future (clock moved back) is stale', () async {
      cache.store['${city.id}_en'] = CachedWeather(
        raw: raw,
        fetchedAt: now.add(const Duration(hours: 1)),
      );
      when(() => api.forecast(any(), lang: any(named: 'lang')))
          .thenAnswer((_) async => raw);
      final r = await repo.load(city, lang: 'en', maxAge: maxAge);
      verify(() => api.forecast(city.query, lang: 'en')).called(1);
      expect(r.bundle.fetchedAt, now);
    });

    City loc(double lat, double lon) => City(
      id: 'loc',
      name: '',
      region: '',
      country: '',
      lat: lat,
      lon: lon,
      isCurrentLocation: true,
    );

    test('current location near the cached place -> cache hit', () async {
      // Fixture location is 51.5171,-0.1062; ~2 km away.
      cache.store['loc_en'] = CachedWeather(raw: raw, fetchedAt: now);
      final r = await repo.load(loc(51.53, -0.08), lang: 'en', maxAge: maxAge);
      expect(r.bundle.cityName, 'London');
      verifyNever(() => api.forecast(any(), lang: any(named: 'lang')));
    });

    test('current location far from the cached place -> fetch', () async {
      cache.store['loc_en'] = CachedWeather(raw: raw, fetchedAt: now);
      when(() => api.forecast(any(), lang: any(named: 'lang')))
          .thenAnswer((_) async => raw);
      final paris = loc(48.85, 2.35);
      await repo.load(paris, lang: 'en', maxAge: maxAge);
      verify(() => api.forecast(paris.query, lang: 'en')).called(1);
    });

    test('far cached place is not used as stale fallback', () async {
      cache.store['loc_en'] = CachedWeather(
        raw: raw,
        fetchedAt: now.subtract(const Duration(hours: 5)),
      );
      when(() => api.forecast(any(), lang: any(named: 'lang')))
          .thenThrow(const WeatherApiException(null, 'offline'));
      expect(
        repo.load(loc(48.85, 2.35), lang: 'en', maxAge: maxAge),
        throwsA(isA<WeatherApiException>()),
      );
    });

    test('search maps results to cities', () async {
      when(() => api.search('lon')).thenAnswer(
        (_) async => [
          {
            'name': 'London',
            'region': 'City of London',
            'country': 'UK',
            'lat': 51.52,
            'lon': -0.11,
          },
        ],
      );
      final cities = await repo.search('lon');
      expect(cities.single.id, '51.52,-0.11');
    });
  });

  group('WeatherApi error mapping', () {
    test('success returns body', () async {
      final api = apiWith((_) => jsonBody(200, {'ok': 1}));
      expect(await api.forecast('1,2', lang: 'en'), {'ok': 1});
    });

    test('HTTP 403 with error body -> API code', () async {
      final api = apiWith(
        (_) => jsonBody(403, {
          'error': {'code': 2007, 'message': 'quota'},
        }),
      );
      expect(
        api.forecast('1,2', lang: 'en'),
        throwsA(
          isA<WeatherApiException>()
              .having((e) => e.code, 'code', 2007)
              .having((e) => e.message, 'message', 'quota'),
        ),
      );
    });

    test('HTTP 400 on search -> API code', () async {
      final api = apiWith(
        (_) => jsonBody(400, {
          'error': {'code': 1006, 'message': 'No matching location found.'},
        }),
      );
      expect(
        api.search('zzz'),
        throwsA(isA<WeatherApiException>().having((e) => e.code, 'code', 1006)),
      );
    });

    test('connection error -> offline', () async {
      final api = apiWith(
        (o) => throw DioException.connectionError(
          requestOptions: o,
          reason: 'down',
        ),
      );
      expect(
        api.forecast('1,2', lang: 'en'),
        throwsA(
          isA<WeatherApiException>()
              .having((e) => e.code, 'code', isNull)
              .having((e) => e.message, 'message', 'offline'),
        ),
      );
    });

    test('timeout -> offline', () async {
      final api = apiWith(
        (o) => throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: o,
        ),
      );
      expect(
        api.search('x'),
        throwsA(
          isA<WeatherApiException>().having((e) => e.message, 'm', 'offline'),
        ),
      );
    });
  });

  group('FileWeatherCache', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('wc'));
    tearDown(() async => dir.delete(recursive: true));

    test('round trip with sanitised id', () async {
      final c = FileWeatherCache(dir);
      final at = DateTime.utc(2026, 11, 9, 10, 30);
      await c.write('51.52,-0.11', {'a': 1}, at);
      expect(File('${dir.path}/51_52__0_11.json').existsSync(), true);
      final r = await c.read('51.52,-0.11');
      expect(r!.raw, {'a': 1});
      expect(r.fetchedAt, at);
    });

    test('missing -> null; creates directory on write', () async {
      final sub = Directory('${dir.path}/nested/x');
      final c = FileWeatherCache(sub);
      expect(await c.read('loc'), isNull);
      await c.write('loc', {'b': 2}, DateTime.utc(2026));
      expect((await c.read('loc'))!.raw, {'b': 2});
    });

    test('corrupt file -> null', () async {
      File('${dir.path}/loc.json').writeAsStringSync('{not json');
      expect(await FileWeatherCache(dir).read('loc'), isNull);
      File('${dir.path}/loc.json').writeAsStringSync('{"fetchedAt":1}');
      expect(await FileWeatherCache(dir).read('loc'), isNull);
    });
  });

  test('cache write failure still returns fresh bundle', () async {
    final api = MockApi();
    when(() => api.forecast(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => raw);
    final r = await WeatherRepository(
      api,
      ThrowingWriteCache(),
      clock: () => now,
    ).load(city, lang: 'en', maxAge: maxAge);
    expect(r.isStale, false);
    expect(r.error, isNull);
    expect(r.bundle.cityName, 'London');
  });

  test('real request URLs keep /v1 and send expected params', () async {
    final seen = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl))
      ..httpClientAdapter = FakeAdapter((o) {
        seen.add(o);
        return jsonBody(200, o.path.contains('search') ? [] : {'ok': 1});
      });
    final api = WeatherApi(dio, key: 'KEY');
    await api.forecast('51.5,-0.1', lang: 'ar');
    await api.search('khar');
    expect(seen[0].uri.host, 'api.weatherapi.com');
    expect(seen[0].uri.path, '/v1/forecast.json');
    expect(seen[0].uri.queryParameters, {
      'key': 'KEY',
      'q': '51.5,-0.1',
      'days': '14',
      'aqi': 'yes',
      'alerts': 'yes',
      'lang': 'ar',
    });
    expect(seen[1].uri.host, 'api.weatherapi.com');
    expect(seen[1].uri.path, '/v1/search.json');
    expect(seen[1].uri.queryParameters, {'key': 'KEY', 'q': 'khar'});
  });

  test('repository treats unmappable cache as no cache', () async {
    final api = MockApi();
    final cache = MemoryCache()
      ..store['${city.id}_en'] = CachedWeather(
        raw: {'junk': 1},
        fetchedAt: now,
      );
    when(() => api.forecast(any(), lang: any(named: 'lang')))
        .thenAnswer((_) async => raw);
    final r = await WeatherRepository(
      api,
      cache,
      clock: () => now,
    ).load(city, lang: 'en', maxAge: maxAge);
    expect(r.bundle.cityName, 'London');
    verify(() => api.forecast(any(), lang: 'en')).called(1);
  });
}
