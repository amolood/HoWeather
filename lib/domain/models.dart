enum TempUnit { c, f }

enum WindUnit { kmh, mph, ms }

class Condition {
  final int code;
  final String text;
  final bool isDay;
  const Condition({
    required this.code,
    required this.text,
    required this.isDay,
  });
}

class AirQuality {
  final int? epaIndex;
  final double? pm25, pm10, o3, no2, so2, co;
  const AirQuality({
    this.epaIndex,
    this.pm25,
    this.pm10,
    this.o3,
    this.no2,
    this.so2,
    this.co,
  });
}

class CurrentWeather {
  final double tempC,
      feelsLikeC,
      windKph,
      gustKph,
      pressureMb,
      visKm,
      uv,
      dewPointC;
  final int humidity, windDegree, cloud;
  final String windDir;
  final Condition condition;
  final AirQuality? air;
  final DateTime updatedAt;
  const CurrentWeather({
    required this.tempC,
    required this.feelsLikeC,
    required this.windKph,
    required this.gustKph,
    required this.pressureMb,
    required this.visKm,
    required this.uv,
    required this.dewPointC,
    required this.humidity,
    required this.windDegree,
    required this.cloud,
    required this.windDir,
    required this.condition,
    this.air,
    required this.updatedAt,
  });
}

class HourlyPoint {
  final DateTime time;
  final double tempC;
  final int chanceOfRain;
  final Condition condition;
  const HourlyPoint({
    required this.time,
    required this.tempC,
    required this.chanceOfRain,
    required this.condition,
  });
}

class DailyPoint {
  final DateTime date;
  final double minC, maxC, uv;
  final int chanceOfRain;
  final Condition condition;

  /// "HH:mm", 24h.
  final String sunrise, sunset, moonPhase;
  const DailyPoint({
    required this.date,
    required this.minC,
    required this.maxC,
    required this.uv,
    required this.chanceOfRain,
    required this.condition,
    required this.sunrise,
    required this.sunset,
    required this.moonPhase,
  });
}

class WeatherAlert {
  final String headline, severity, event, desc;
  const WeatherAlert({
    required this.headline,
    required this.severity,
    required this.event,
    required this.desc,
  });

  @override
  bool operator ==(Object other) =>
      other is WeatherAlert &&
      other.headline == headline &&
      other.severity == severity &&
      other.event == event &&
      other.desc == desc;

  @override
  int get hashCode => Object.hash(headline, severity, event, desc);
}

class WeatherBundle {
  final String cityName, region, country, tzId;

  /// Coordinates of the place the forecast is for (API `location`).
  final double lat, lon;

  /// City's current offset from UTC.
  final Duration utcOffset;
  final CurrentWeather current;
  final List<HourlyPoint> hourly;
  final List<DailyPoint> daily;
  final List<WeatherAlert> alerts;
  final DateTime fetchedAt;
  const WeatherBundle({
    required this.cityName,
    required this.region,
    required this.country,
    required this.tzId,
    required this.lat,
    required this.lon,
    required this.utcOffset,
    required this.current,
    required this.hourly,
    required this.daily,
    required this.alerts,
    required this.fetchedAt,
  });

  /// UTC-flagged DateTime whose fields are the city's wall-clock time.
  DateTime toCityTime(DateTime utcInstant) => utcInstant.toUtc().add(utcOffset);
}

class City {
  /// `'lat2,lon2'` (two decimals), or `'loc'` for the current location.
  final String id;
  final String name, region, country;
  final double lat, lon;
  final bool isCurrentLocation;
  const City({
    required this.id,
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    this.isCurrentLocation = false,
  });

  String get query => '$lat,$lon';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'region': region,
    'country': country,
    'lat': lat,
    'lon': lon,
    'isCurrentLocation': isCurrentLocation,
  };

  factory City.fromJson(Map<String, dynamic> j) => City(
    id: j['id'] as String,
    name: j['name'] as String,
    region: j['region'] as String,
    country: j['country'] as String,
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
    isCurrentLocation: j['isCurrentLocation'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      other is City &&
      other.id == id &&
      other.name == name &&
      other.region == region &&
      other.country == country &&
      other.lat == lat &&
      other.lon == lon &&
      other.isCurrentLocation == isCurrentLocation;

  @override
  int get hashCode =>
      Object.hash(id, name, region, country, lat, lon, isCurrentLocation);
}
