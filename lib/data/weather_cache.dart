import 'dart:convert';
import 'dart:io';

class CachedWeather {
  final Map<String, dynamic> raw;
  final DateTime fetchedAt;
  const CachedWeather({required this.raw, required this.fetchedAt});
}

abstract class WeatherCache {
  Future<CachedWeather?> read(String cityId);
  Future<void> write(
    String cityId,
    Map<String, dynamic> raw,
    DateTime fetchedAt,
  );
}

class FileWeatherCache implements WeatherCache {
  final Directory dir;
  const FileWeatherCache(this.dir);

  File _file(String cityId) =>
      File('${dir.path}/${cityId.replaceAll(RegExp(r'[,.\-]'), '_')}.json');

  @override
  Future<CachedWeather?> read(String cityId) async {
    try {
      final f = _file(cityId);
      if (!await f.exists()) return null;
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return CachedWeather(
        raw: j['raw'] as Map<String, dynamic>,
        fetchedAt: DateTime.parse(j['fetchedAt'] as String),
      );
    } catch (_) {
      return null; // corrupt cache == no cache
    }
  }

  @override
  Future<void> write(
    String cityId,
    Map<String, dynamic> raw,
    DateTime fetchedAt,
  ) async {
    await dir.create(recursive: true);
    await _file(cityId).writeAsString(
      jsonEncode({
        'fetchedAt': fetchedAt.toUtc().toIso8601String(),
        'raw': raw,
      }),
    );
  }
}
