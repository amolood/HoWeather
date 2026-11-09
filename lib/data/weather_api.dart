import 'package:dio/dio.dart';

import 'weather_mapper.dart';

class WeatherApi {
  final Dio _dio;
  final String _key;

  WeatherApi(this._dio, {required this._key}) {
    _dio.options
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 10)
      ..sendTimeout = const Duration(seconds: 10);
  }

  Future<Map<String, dynamic>> forecast(
    String q, {
    required String lang,
  }) async {
    final data = await _get('/forecast.json', {
      'q': q,
      'days': 14,
      'aqi': 'yes',
      'alerts': 'yes',
      'lang': lang,
    });
    if (data is! Map<String, dynamic>) {
      throw const WeatherApiException(null, 'Unexpected response');
    }
    return data;
  }

  Future<List<dynamic>> search(String q) async {
    final data = await _get('/search.json', {'q': q});
    if (data is! List) {
      if (data is Map<String, dynamic>) throwIfApiError(data);
      throw const WeatherApiException(null, 'Unexpected response');
    }
    return data;
  }

  Future<Object?> _get(String path, Map<String, Object> params) async {
    try {
      final res = await _dio.get<Object?>(
        path,
        queryParameters: {'key': _key, ...params},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) throwIfApiError(data);
      return data;
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map<String, dynamic>) throwIfApiError(body);
      if (e.response != null) {
        throw WeatherApiException(null, 'HTTP ${e.response!.statusCode}');
      }
      throw const WeatherApiException(null, 'offline');
    }
  }
}
