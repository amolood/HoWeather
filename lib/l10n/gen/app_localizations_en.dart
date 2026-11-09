// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HoWeather';

  @override
  String get hourly => 'Hourly forecast';

  @override
  String forecastDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day forecast',
      one: '1-day forecast',
    );
    return '$_temp0';
  }

  @override
  String get airQuality => 'Air quality';

  @override
  String get uvIndex => 'UV index';

  @override
  String get wind => 'Wind';

  @override
  String get humidity => 'Humidity';

  @override
  String get pressure => 'Pressure';

  @override
  String get visibility => 'Visibility';

  @override
  String get sunriseSunset => 'Sunrise & sunset';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get sunset => 'Sunset';

  @override
  String get dailyBrief => 'Daily brief';

  @override
  String feelsLike(String temp) {
    return 'Feels like $temp';
  }

  @override
  String high(String temp) {
    return 'H $temp';
  }

  @override
  String low(String temp) {
    return 'L $temp';
  }

  @override
  String get aqiGood => 'Good';

  @override
  String get aqiModerate => 'Moderate';

  @override
  String get aqiUnhealthySensitive => 'Unhealthy for sensitive groups';

  @override
  String get aqiUnhealthy => 'Unhealthy';

  @override
  String get aqiVeryUnhealthy => 'Very unhealthy';

  @override
  String get aqiHazardous => 'Hazardous';

  @override
  String get noData => 'No data';

  @override
  String get today => 'Today';

  @override
  String get now => 'Now';

  @override
  String dewPoint(String temp) {
    return 'Dew point $temp';
  }

  @override
  String gusts(String value) {
    return 'Gusts $value';
  }

  @override
  String get lifeDress => 'Dress';

  @override
  String get lifeCarWash => 'Car wash';

  @override
  String get lifeSport => 'Sport';

  @override
  String get lifeUmbrella => 'Umbrella';

  @override
  String get lifeSunCream => 'Sun cream';

  @override
  String get lifeAllergy => 'Allergy';

  @override
  String get dressWarm => 'Warm clothes';

  @override
  String get dressLight => 'Light layers';

  @override
  String get dressCool => 'Cool clothes';

  @override
  String get carWashGood => 'Good';

  @override
  String get carWashPoor => 'Not ideal';

  @override
  String get sportIdeal => 'Ideal';

  @override
  String get sportPoor => 'Poor';

  @override
  String get umbrellaYes => 'Take one';

  @override
  String get umbrellaNo => 'Not needed';

  @override
  String get uvLow => 'Low';

  @override
  String get uvModerate => 'Moderate';

  @override
  String get uvHigh => 'High';

  @override
  String get allergyLow => 'Low';

  @override
  String get allergyModerate => 'Moderate';

  @override
  String get allergyHigh => 'High';

  @override
  String get unitKmh => 'km/h';

  @override
  String get unitMph => 'mph';

  @override
  String get unitMs => 'm/s';

  @override
  String get unitMb => 'mb';

  @override
  String get unitKm => 'km';

  @override
  String get unitPercent => '%';

  @override
  String get dirN => 'N';

  @override
  String get dirNNE => 'NNE';

  @override
  String get dirNE => 'NE';

  @override
  String get dirENE => 'ENE';

  @override
  String get dirE => 'E';

  @override
  String get dirESE => 'ESE';

  @override
  String get dirSE => 'SE';

  @override
  String get dirSSE => 'SSE';

  @override
  String get dirS => 'S';

  @override
  String get dirSSW => 'SSW';

  @override
  String get dirSW => 'SW';

  @override
  String get dirWSW => 'WSW';

  @override
  String get dirW => 'W';

  @override
  String get dirWNW => 'WNW';

  @override
  String get dirNW => 'NW';

  @override
  String get dirNNW => 'NNW';

  @override
  String updatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get staleLabel => 'Showing saved data';

  @override
  String get dataSource => 'WeatherAPI.com';

  @override
  String get retry => 'Retry';

  @override
  String get errorOffline => 'You\'re offline';

  @override
  String get errorGeneric => 'Couldn\'t load the weather';

  @override
  String get errorKey => 'API key is invalid';

  @override
  String get errorQuota => 'Monthly API quota exceeded';

  @override
  String get errorNotFound => 'Location not found';

  @override
  String get searchCity => 'Search a city';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get noCitiesTitle => 'No cities yet';

  @override
  String get myLocation => 'My location';

  @override
  String get cities => 'Cities';

  @override
  String get addCity => 'Add city';

  @override
  String get searchHint => 'Search for a city';

  @override
  String get noResults => 'No cities found';

  @override
  String get cityLimitReached => 'You can save up to 10 cities';

  @override
  String get delete => 'Delete';

  @override
  String get settings => 'Settings';

  @override
  String get temperatureUnit => 'Temperature unit';

  @override
  String get windUnit => 'Wind speed unit';

  @override
  String get autoUpdate => 'Auto update';

  @override
  String get manual => 'Manual';

  @override
  String everyHours(int n) {
    return 'Every $n h';
  }

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get about => 'About';

  @override
  String get dataAttribution => 'Weather data by WeatherAPI.com';

  @override
  String get unitCelsius => '°C';

  @override
  String get unitFahrenheit => '°F';

  @override
  String get version => 'Version';

  @override
  String get locationDenied => 'Location access is off. Allow it in Settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get humidityDry => 'Dry';

  @override
  String get humidityComfortable => 'Normal';

  @override
  String get humidityHumid => 'Humid';

  @override
  String get pressureLow => 'Low';

  @override
  String get pressureNormal => 'Normal';

  @override
  String get pressureHigh => 'High';

  @override
  String pressureInfo(String value) {
    return '$value inHg';
  }

  @override
  String get visPoor => 'Poor';

  @override
  String get visFair => 'Fair';

  @override
  String get visGood => 'Good';

  @override
  String get visExcellent => 'Excellent';

  @override
  String visInfo(String value) {
    return '$value mi';
  }

  @override
  String uvPeak(String value) {
    return 'Today\'s peak $value';
  }

  @override
  String daylight(String duration) {
    return 'Daylight $duration';
  }

  @override
  String durationHm(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String get moonNew => 'New moon';

  @override
  String get moonWaxingCrescent => 'Waxing crescent';

  @override
  String get moonFirstQuarter => 'First quarter';

  @override
  String get moonWaxingGibbous => 'Waxing gibbous';

  @override
  String get moonFull => 'Full moon';

  @override
  String get moonWaningGibbous => 'Waning gibbous';

  @override
  String get moonLastQuarter => 'Last quarter';

  @override
  String get moonWaningCrescent => 'Waning crescent';

  @override
  String get weatherAlert => 'Weather alert';

  @override
  String alertsMore(int n) {
    return '+$n more';
  }

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageHint =>
      'Weather descriptions and official alerts are shown in this language.';

  @override
  String get units => 'Units';

  @override
  String get translating => 'Translating…';

  @override
  String get alertOriginalText => 'Original text';

  @override
  String get translationUnavailable =>
      'Couldn\'t translate it. Tap to read the original.';

  @override
  String get translatedAutomatically => 'Translated automatically';

  @override
  String hoursShort(int n) {
    return '$n h';
  }

  @override
  String get refreshManualHint => 'Updates only when you pull to refresh.';

  @override
  String get listSeparator => ', ';
}
