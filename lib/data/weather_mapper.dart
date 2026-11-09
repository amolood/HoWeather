import '../domain/models.dart';

class WeatherApiException implements Exception {
  final int? code;
  final String message;
  const WeatherApiException(this.code, this.message);

  @override
  String toString() => 'WeatherApiException($code): $message';
}

void throwIfApiError(Map<String, dynamic> json) {
  final error = json['error'];
  if (error is Map) {
    throw WeatherApiException(
      (error['code'] as num?)?.toInt(),
      error['message']?.toString() ?? 'Unknown error',
    );
  }
}

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
int _i(Object? v) => (v as num?)?.toInt() ?? 0;

DateTime _fromEpoch(Object? seconds) =>
    DateTime.fromMillisecondsSinceEpoch(_i(seconds) * 1000, isUtc: true);

Condition _condition(Map<String, dynamic> j, {required bool isDay}) {
  final c = j['condition'] as Map<String, dynamic>? ?? const {};
  return Condition(
    code: _i(c['code']),
    text: c['text'] as String? ?? '',
    isDay: isDay,
  );
}

/// "07:08 AM" -> "07:08"; anything unparseable ("No sunrise") -> "--:--".
String _to24h(Object? raw) {
  final m = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*([AaPp][Mm])\s*$')
      .firstMatch(raw?.toString() ?? '');
  if (m == null) return '--:--';
  var h = int.parse(m.group(1)!) % 12;
  if (m.group(3)!.toLowerCase() == 'pm') h += 12;
  return '${h.toString().padLeft(2, '0')}:${m.group(2)}';
}

AirQuality? _air(Object? raw) {
  if (raw is! Map) return null;
  double? n(String k) => (raw[k] as num?)?.toDouble();
  return AirQuality(
    epaIndex: (raw['us-epa-index'] as num?)?.toInt(),
    pm25: n('pm2_5'),
    pm10: n('pm10'),
    o3: n('o3'),
    no2: n('no2'),
    so2: n('so2'),
    co: n('co'),
  );
}

WeatherBundle mapForecast(
  Map<String, dynamic> json, {
  required DateTime fetchedAt,
}) {
  throwIfApiError(json);
  try {
    return _mapForecast(json, fetchedAt);
  } on WeatherApiException {
    rethrow;
  } catch (_) {
    throw const WeatherApiException(null, 'Unexpected response');
  }
}

Duration _utcOffset(Map<String, dynamic> loc) {
  final m = RegExp(r'^\s*(\d{4})-(\d{2})-(\d{2}) (\d{1,2}):(\d{2})')
      .firstMatch(loc['localtime'] as String);
  if (m == null) throw const FormatException('bad localtime');
  final wall = DateTime.utc(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
  );
  final raw = wall.difference(_fromEpoch(loc['localtime_epoch']));
  const q = 15 * 60 * 1000000;
  return Duration(microseconds: (raw.inMicroseconds / q).round() * q);
}

WeatherBundle _mapForecast(Map<String, dynamic> json, DateTime fetchedAt) {
  final loc = json['location'] as Map<String, dynamic>;
  final cur = json['current'] as Map<String, dynamic>;
  final days = (json['forecast']?['forecastday'] as List? ?? const [])
      .cast<Map<String, dynamic>>();

  final current = CurrentWeather(
    tempC: _d(cur['temp_c']),
    feelsLikeC: _d(cur['feelslike_c']),
    windKph: _d(cur['wind_kph']),
    gustKph: _d(cur['gust_kph']),
    pressureMb: _d(cur['pressure_mb']),
    visKm: _d(cur['vis_km']),
    uv: _d(cur['uv']),
    dewPointC: _d(cur['dewpoint_c']),
    humidity: _i(cur['humidity']),
    windDegree: _i(cur['wind_degree']),
    cloud: _i(cur['cloud']),
    windDir: cur['wind_dir'] as String? ?? '',
    condition: _condition(cur, isDay: _i(cur['is_day']) == 1),
    air: _air(cur['air_quality']),
    updatedAt: _fromEpoch(cur['last_updated_epoch']),
  );

  // Flatten every hour, then take 24 starting at the hour containing "now"
  // (the latest hour whose epoch is <= last_updated_epoch). Works for
  // half-hour time zones too.
  final hours = <Map<String, dynamic>>[
    for (final d in days)
      ...(d['hour'] as List? ?? const []).cast<Map<String, dynamic>>(),
  ]..sort((a, b) => _i(a['time_epoch']).compareTo(_i(b['time_epoch'])));
  final nowEpoch = _i(cur['last_updated_epoch']);
  var start = hours.lastIndexWhere((h) => _i(h['time_epoch']) <= nowEpoch);
  if (start < 0) start = 0;
  final hourly = [
    for (final h in hours.skip(start).take(24))
      HourlyPoint(
        time: _fromEpoch(h['time_epoch']),
        tempC: _d(h['temp_c']),
        chanceOfRain: _i(h['chance_of_rain']),
        condition: _condition(h, isDay: _i(h['is_day']) == 1),
      ),
  ];

  final daily = [
    for (final d in days)
      () {
        final day = d['day'] as Map<String, dynamic>;
        final astro = d['astro'] as Map<String, dynamic>? ?? const {};
        return DailyPoint(
          date: DateTime.parse('${d['date']}T00:00:00Z'),
          minC: _d(day['mintemp_c']),
          maxC: _d(day['maxtemp_c']),
          uv: _d(day['uv']),
          chanceOfRain: _i(day['daily_chance_of_rain']),
          condition: _condition(day, isDay: true),
          sunrise: _to24h(astro['sunrise']),
          sunset: _to24h(astro['sunset']),
          moonPhase: astro['moon_phase'] as String? ?? '',
        );
      }(),
  ];

  final alerts = [
    for (final a in (json['alerts']?['alert'] as List? ?? const []))
      WeatherAlert(
        headline: a['headline'] as String? ?? '',
        severity: a['severity'] as String? ?? '',
        event: a['event'] as String? ?? '',
        desc: a['desc'] as String? ?? '',
      ),
  ];

  return WeatherBundle(
    cityName: loc['name'] as String? ?? '',
    region: loc['region'] as String? ?? '',
    country: loc['country'] as String? ?? '',
    tzId: loc['tz_id'] as String? ?? '',
    lat: _d(loc['lat']),
    lon: _d(loc['lon']),
    utcOffset: _utcOffset(loc),
    current: current,
    hourly: hourly,
    daily: daily,
    alerts: alerts,
    fetchedAt: fetchedAt,
  );
}

List<City> mapSearch(List<dynamic> json) => [
  for (final e in json.cast<Map<String, dynamic>>())
    () {
      final lat = _d(e['lat']);
      final lon = _d(e['lon']);
      return City(
        id: '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}',
        name: e['name'] as String? ?? '',
        region: e['region'] as String? ?? '',
        country: e['country'] as String? ?? '',
        lat: lat,
        lon: lon,
      );
    }(),
];
