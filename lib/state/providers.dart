import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/location_service.dart';
import '../data/text_translator.dart';
import '../data/prefs_store.dart';
import '../data/weather_repository.dart';
import '../domain/alerts.dart';
import '../domain/models.dart';

const _minRefresh = Duration(minutes: 10);
const _manualMaxAge = Duration(days: 100);

final prefsStoreProvider = Provider<PrefsStore>(
  (ref) => throw UnimplementedError('override prefsStoreProvider'),
);
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => throw UnimplementedError('override weatherRepositoryProvider'),
);
final locationServiceProvider = Provider<LocationService>(
  (ref) => throw UnimplementedError('override locationServiceProvider'),
);

/// Wall clock; overridable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Device locale; initialised in `main()`, overridable in tests.
class LocaleNotifier extends Notifier<Locale> {
  LocaleNotifier(this.initial);
  final Locale initial;

  @override
  Locale build() => initial;
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  () => LocaleNotifier(const Locale('en')),
);

String langOf(Locale l) => l.languageCode == 'ar' ? 'ar' : 'en';

/// The locale the app shows: the user's choice in Settings, or the device
/// locale for [AppLanguage.system]. Drives the UI, the API's `lang` and
/// alert translation.
final appLocaleProvider = Provider<Locale>((ref) {
  final device = ref.watch(localeProvider);
  return switch (ref.watch(settingsProvider.select((s) => s.language))) {
    AppLanguage.system => device,
    AppLanguage.en => const Locale('en'),
    AppLanguage.ar => const Locale('ar'),
  };
});

class PageIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int i) => state = i;
}

final pageIndexProvider = NotifierProvider<PageIndexNotifier, int>(
  PageIndexNotifier.new,
);

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() =>
      ref.read(prefsStoreProvider).loadSettings(ref.read(localeProvider));

  Future<void> update(Settings s) async {
    state = s;
    await ref.read(prefsStoreProvider).saveSettings(s);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);

class CitiesNotifier extends AsyncNotifier<List<City>> {
  PrefsStore get _prefs => ref.read(prefsStoreProvider);

  /// Returns the saved cities at once; the current location is resolved
  /// afterwards and merged in when it arrives.
  @override
  FutureOr<List<City>> build() {
    unawaited(_attachLocation());
    return _prefs.loadCities();
  }

  Future<void> _attachLocation() async {
    final loc = await resolveCurrentCity(
      ref.read(locationServiceProvider),
      ref.read(weatherRepositoryProvider),
    );
    if (loc == null || !ref.mounted) return;
    final List<City> updated;
    try {
      updated = addCity(_current, loc);
    } on CityLimitException {
      return; // the 10-city cap counts the location city; keep the saved ones
    }
    await _commit(updated);
  }

  /// The loaded list; falls back to the persisted one so a mutation never
  /// overwrites saved cities from an unknown (loading/errored) state.
  List<City> get _current => state.value ?? _prefs.loadCities();

  Future<void> _commit(List<City> list) async {
    await _prefs.saveCities(list);
    state = AsyncData(list);
  }

  /// Throws [CityLimitException] when the list is full.
  Future<void> add(City c) async => _commit(addCity(_current, c));

  Future<void> remove(String id) async => _commit(removeCity(_current, id));

  Future<void> move(int from, int to) async =>
      _commit(moveCity(_current, from, to));

  /// Resolves the device location and inserts it; returns the outcome so
  /// the UI can explain a denial. Throws [CityLimitException] when full.
  Future<LocationOutcome> refreshLocation() async {
    final outcome = await ref.read(locationServiceProvider).current();
    if (outcome is! LocationFound) return outcome;
    final loc = await cityAt(outcome, ref.read(weatherRepositoryProvider));
    await _commit(addCity(_current, loc));
    return outcome;
  }
}

final citiesProvider = AsyncNotifierProvider<CitiesNotifier, List<City>>(
  CitiesNotifier.new,
);

class WeatherNotifier extends AsyncNotifier<WeatherResult> {
  WeatherNotifier(this.city);
  final City city;

  // Settings are read, not watched: unit/interval changes must not refetch.
  Duration get _maxAge {
    final refresh = ref.read(settingsProvider).refresh;
    final age = refresh == Duration.zero ? _manualMaxAge : refresh;
    return age < _minRefresh ? _minRefresh : age;
  }

  Future<WeatherResult> _load(String lang, {bool force = false}) => ref
      .read(weatherRepositoryProvider)
      .load(city, lang: lang, maxAge: _maxAge, force: force);

  bool _force = false;

  @override
  Future<WeatherResult> build() {
    final force = _force;
    _force = false;
    return _load(langOf(ref.watch(appLocaleProvider)), force: force);
  }

  /// Re-runs [build] with `force: true`; the previous value stays available
  /// (as a reloading state) until the new one arrives.
  Future<void> refresh() async {
    _force = true;
    ref.invalidateSelf(asReload: true);
    try {
      await future;
    } catch (_) {
      // The error is exposed through [state].
    }
  }
}

final weatherProvider =
    AsyncNotifierProvider.family<WeatherNotifier, WeatherResult, City>(
      WeatherNotifier.new,
    );

/// Translator for official alerts; `main()` wires ML Kit.
final textTranslatorProvider = Provider<TextTranslator>(
  (ref) => const PassThroughTranslator(),
);

/// [WeatherAlert] in the app language `(alert, 'en' | 'ar')`. Alerts already
/// in that language come back as they are; others are translated on device.
/// Fails with [TranslationUnavailable] when they can't be.
final translatedAlertProvider =
    FutureProvider.family<WeatherAlert, (WeatherAlert, String)>((
      ref,
      arg,
    ) async {
      final (a, lang) = arg;
      if (alertMatchesLanguage(a, lang)) return a;
      final t = ref.read(textTranslatorProvider);
      Future<String> tr(String s) async =>
          s.trim().isEmpty ? s : t.translate(s, lang);
      final event = await tr(a.event);
      final headline = a.headline == a.event ? event : await tr(a.headline);
      return WeatherAlert(
        headline: headline,
        severity: a.severity,
        event: event,
        desc: await tr(a.desc),
      );
      // A failed translation shows the original at once; no retry loop.
    }, retry: (_, _) => null);

/// A place name (city, region or country; WeatherAPI gives them in English)
/// in the app language `(name, 'en' | 'ar')`. Never fails: falls back to
/// the name as given.
final placeNameProvider = FutureProvider.family<String, (String, String)>((
  ref,
  arg,
) async {
  final (name, lang) = arg;
  if (lang != 'ar' || name.trim().isEmpty || textMatchesLanguage(name, 'ar')) {
    return name;
  }
  try {
    return await ref
        .read(textTranslatorProvider)
        .translate(name, 'ar', from: 'en');
  } catch (_) {
    return name;
  }
}, retry: (_, _) => null);

/// [name] in the current app language, or as given until translated.
String placeName(WidgetRef ref, String name, Locale locale) => ref
    .watch(placeNameProvider((name, langOf(locale))))
    .maybeWhen(data: (v) => v, orElse: () => name);
