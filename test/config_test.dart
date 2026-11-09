import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/config.dart';

void main() {
  test('baseUrl is the WeatherAPI v1 endpoint', () {
    expect(AppConfig.baseUrl, 'https://api.weatherapi.com/v1');
  });

  test('hasKey is false when no define is passed', () {
    expect(AppConfig.hasKey, isFalse);
  });
}
