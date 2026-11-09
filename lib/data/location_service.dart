import 'package:geolocator/geolocator.dart';

import '../domain/models.dart';
import 'weather_repository.dart';

sealed class LocationOutcome {
  const LocationOutcome();
}

class LocationFound extends LocationOutcome {
  final double lat, lon;
  const LocationFound(this.lat, this.lon);
}

class LocationDenied extends LocationOutcome {
  const LocationDenied();
}

class LocationUnavailable extends LocationOutcome {
  const LocationUnavailable();
}

abstract class LocationService {
  Future<LocationOutcome> current();

  /// Opens the app's system settings page (to grant location access).
  Future<void> openSettings();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<LocationOutcome> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationUnavailable();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationDenied();
      }
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );
        return LocationFound(p.latitude, p.longitude);
      } catch (_) {
        final last = await Geolocator.getLastKnownPosition();
        return last == null
            ? const LocationUnavailable()
            : LocationFound(last.latitude, last.longitude);
      }
    } catch (_) {
      return const LocationUnavailable();
    }
  }
}

/// Resolves the device position to a [City] with id `'loc'`. Returns null when
/// location is denied or unavailable. If the reverse lookup fails, the city is
/// returned with an empty name (the UI shows "My location").
Future<City?> resolveCurrentCity(
  LocationService loc,
  WeatherRepository repo,
) async {
  final outcome = await loc.current();
  if (outcome is! LocationFound) return null;
  return cityAt(outcome, repo);
}

/// The current-location [City] for a resolved position; see
/// [resolveCurrentCity].
Future<City> cityAt(LocationFound outcome, WeatherRepository repo) async {
  City? match;
  try {
    final results = await repo.search('${outcome.lat},${outcome.lon}');
    if (results.isNotEmpty) match = results.first;
  } catch (_) {}
  return City(
    id: 'loc',
    name: match?.name ?? '',
    region: match?.region ?? '',
    country: match?.country ?? '',
    lat: outcome.lat,
    lon: outcome.lon,
    isCurrentLocation: true,
  );
}
