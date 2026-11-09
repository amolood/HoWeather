import 'dart:convert';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

enum ThemePref { system, light, dark }

/// App language; [system] follows the device (Arabic or English).
enum AppLanguage { system, en, ar }

const _fahrenheitCountries = {'US', 'LR', 'MM', 'BS', 'BZ', 'KY', 'PW'};
const _defaultRefresh = Duration(hours: 1);
const _allowedRefresh = [
  Duration.zero,
  Duration(hours: 1),
  Duration(hours: 3),
  Duration(hours: 6),
];

class Settings {
  final TempUnit temp;
  final WindUnit wind;

  /// [Duration.zero] means manual refresh only.
  final Duration refresh;
  final ThemePref theme;
  final AppLanguage language;

  const Settings({
    required this.temp,
    required this.wind,
    required this.refresh,
    required this.theme,
    this.language = AppLanguage.system,
  });

  Settings copyWith({
    TempUnit? temp,
    WindUnit? wind,
    Duration? refresh,
    ThemePref? theme,
    AppLanguage? language,
  }) => Settings(
    temp: temp ?? this.temp,
    wind: wind ?? this.wind,
    refresh: refresh ?? this.refresh,
    theme: theme ?? this.theme,
    language: language ?? this.language,
  );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.temp == temp &&
      other.wind == wind &&
      other.refresh == refresh &&
      other.theme == theme &&
      other.language == language;

  @override
  int get hashCode => Object.hash(temp, wind, refresh, theme, language);
}

class CityLimitException implements Exception {
  const CityLimitException();
  @override
  String toString() => 'CityLimitException: at most $maxCities cities';
}

const maxCities = 10;

class PrefsStore {
  static const _kTemp = 'temp';
  static const _kWind = 'wind';
  static const _kRefresh = 'refresh_min';
  static const _kTheme = 'theme';
  static const _kLanguage = 'language';
  static const _kCities = 'cities';

  final SharedPreferences _p;
  PrefsStore(this._p);

  Settings loadSettings(Locale l) {
    final defaultTemp = _fahrenheitCountries.contains(l.countryCode)
        ? TempUnit.f
        : TempUnit.c;
    final minutes = _p.getInt(_kRefresh);
    final stored = minutes == null ? null : Duration(minutes: minutes);
    return Settings(
      temp: _byName(TempUnit.values, _p.getString(_kTemp)) ?? defaultTemp,
      wind: _byName(WindUnit.values, _p.getString(_kWind)) ?? WindUnit.kmh,
      refresh: _allowedRefresh.contains(stored) ? stored! : _defaultRefresh,
      theme:
          _byName(ThemePref.values, _p.getString(_kTheme)) ?? ThemePref.system,
      language:
          _byName(AppLanguage.values, _p.getString(_kLanguage)) ??
          AppLanguage.system,
    );
  }

  Future<void> saveSettings(Settings s) async {
    await _p.setString(_kTemp, s.temp.name);
    await _p.setString(_kWind, s.wind.name);
    await _p.setInt(_kRefresh, s.refresh.inMinutes);
    await _p.setString(_kTheme, s.theme.name);
    await _p.setString(_kLanguage, s.language.name);
  }

  List<City> loadCities() {
    final raw = _p.getString(_kCities);
    if (raw == null) return const [];
    try {
      return [
        for (final j in jsonDecode(raw) as List)
          City.fromJson(j as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCities(List<City> c) => _p
      .setString(_kCities, jsonEncode([for (final x in c) x.toJson()]))
      .then((_) {});
}

T? _byName<T extends Enum>(List<T> values, String? name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

/// Adds [c]. Duplicate ids are a no-op; a `loc` city goes to (or replaces)
/// index 0. Throws [CityLimitException] when a new city would exceed 10.
List<City> addCity(List<City> list, City c) {
  final existing = list.indexWhere((x) => x.id == c.id);
  if (c.isCurrentLocation) {
    if (existing >= 0) return [...list]..[existing] = c;
    if (list.length >= maxCities) throw const CityLimitException();
    return [c, ...list];
  }
  if (existing >= 0) return list;
  if (list.length >= maxCities) throw const CityLimitException();
  return [...list, c];
}

List<City> removeCity(List<City> list, String id) => [
  for (final c in list)
    if (c.id != id) c,
];

/// Moves the item at [from] to [to] (list indices). The current-location city,
/// when at index 0, stays there: it cannot be moved and nothing moves above it.
List<City> moveCity(List<City> list, int from, int to) {
  if (from < 0 || from >= list.length) return list;
  final locFirst = list.isNotEmpty && list[0].isCurrentLocation;
  if (locFirst && from == 0) return list;
  final lo = locFirst ? 1 : 0;
  final dest = to.clamp(lo, list.length - 1);
  if (dest == from) return list;
  final out = [...list];
  out.insert(dest, out.removeAt(from));
  return out;
}
