import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/data/location_service.dart';
import 'package:howeather/data/weather_repository.dart';
import 'package:howeather/domain/models.dart';
import 'package:mocktail/mocktail.dart';

class MockRepo extends Mock implements WeatherRepository {}

class FakeLocation implements LocationService {
  final LocationOutcome outcome;
  FakeLocation(this.outcome);
  @override
  Future<LocationOutcome> current() async => outcome;

  @override
  Future<void> openSettings() async {}
}

void main() {
  late MockRepo repo;
  setUp(() => repo = MockRepo());

  const found = City(
    id: '21.42,39.83',
    name: 'Mecca',
    region: 'Makkah',
    country: 'Saudi Arabia',
    lat: 21.4,
    lon: 39.8,
  );

  test('found: city uses GPS coords and first search result names', () async {
    when(() => repo.search(any())).thenAnswer((_) async => [found]);
    final city = await resolveCurrentCity(
      FakeLocation(const LocationFound(21.5, 39.9)),
      repo,
    );
    expect(city!.id, 'loc');
    expect(city.isCurrentLocation, isTrue);
    expect(city.name, 'Mecca');
    expect(city.region, 'Makkah');
    expect(city.country, 'Saudi Arabia');
    expect(city.lat, 21.5);
    expect(city.lon, 39.9);
    verify(() => repo.search('21.5,39.9')).called(1);
  });

  test('search throws: still returns a city with empty name', () async {
    when(() => repo.search(any())).thenThrow(Exception('offline'));
    final city = await resolveCurrentCity(
      FakeLocation(const LocationFound(1, 2)),
      repo,
    );
    expect(city!.id, 'loc');
    expect(city.name, '');
    expect(city.region, '');
    expect(city.country, '');
    expect(city.lat, 1);
    expect(city.lon, 2);
  });

  test('search empty: still returns a city with empty name', () async {
    when(() => repo.search(any())).thenAnswer((_) async => []);
    final city = await resolveCurrentCity(
      FakeLocation(const LocationFound(1, 2)),
      repo,
    );
    expect(city!.name, '');
    expect(city.isCurrentLocation, isTrue);
  });

  test('denied and unavailable give null', () async {
    expect(
      await resolveCurrentCity(FakeLocation(const LocationDenied()), repo),
      isNull,
    );
    expect(
      await resolveCurrentCity(FakeLocation(const LocationUnavailable()), repo),
      isNull,
    );
    verifyNever(() => repo.search(any()));
  });
}
