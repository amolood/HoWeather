import 'dart:math' as math;

import '../domain/models.dart';
import 'weather_api.dart';
import 'weather_cache.dart';
import 'weather_mapper.dart';

class WeatherResult {
  final WeatherBundle bundle;
  final bool isStale;
  final WeatherApiException? error;
  const WeatherResult(this.bundle, {this.isStale = false, this.error});
}

class WeatherRepository {
  final WeatherApi _api;
  final WeatherCache _cache;
  final DateTime Function() _clock;

  WeatherRepository(this._api, this._cache, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  Future<WeatherResult> load(
    City city, {
    required String lang,
    required Duration maxAge,
    bool force = false,
  }) async {
    final now = _clock();
    final key = '${city.id}_$lang';
    final cached = await _cache.read(key);
    WeatherBundle? cachedBundle;
    if (cached != null) {
      try {
        cachedBundle = mapForecast(cached.raw, fetchedAt: cached.fetchedAt);
      } on WeatherApiException {
        cachedBundle = null; // unusable cache == no cache
      }
      // The current-location city keeps id 'loc' when the device moves, so a
      // cached forecast for a different place must not be shown under it.
      if (cachedBundle != null &&
          city.isCurrentLocation &&
          _distanceKm(cachedBundle.lat, cachedBundle.lon, city.lat, city.lon) >
              _maxLocDriftKm) {
        cachedBundle = null;
      }
    }

    if (!force && cachedBundle != null) {
      // A negative age (clock moved back) counts as stale.
      final age = now.difference(cached!.fetchedAt);
      if (!age.isNegative && age < maxAge) return WeatherResult(cachedBundle);
    }

    try {
      final raw = await _api.forecast(city.query, lang: lang);
      final bundle = mapForecast(raw, fetchedAt: now);
      try {
        await _cache.write(key, raw, now);
      } catch (_) {
        // A failed cache write must not discard a fresh bundle.
      }
      return WeatherResult(bundle);
    } on WeatherApiException catch (e) {
      if (cachedBundle == null) rethrow;
      return WeatherResult(cachedBundle, isStale: true, error: e);
    }
  }

  static const _maxLocDriftKm = 5.0;

  /// Equirectangular approximation; accurate enough at a few km.
  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthKm = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final x = rad(lon2 - lon1) * math.cos(rad((lat1 + lat2) / 2));
    final y = rad(lat2 - lat1);
    return earthKm * math.sqrt(x * x + y * y);
  }

  Future<List<City>> search(String q) async => mapSearch(await _api.search(q));
}
