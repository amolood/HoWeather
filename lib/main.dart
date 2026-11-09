import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'data/location_service.dart';
import 'data/prefs_store.dart';
import 'data/text_translator.dart';
import 'data/weather_api.dart';
import 'data/weather_cache.dart';
import 'data/weather_repository.dart';
import 'l10n/gen/app_localizations.dart';
import 'state/providers.dart';
import 'ui/cities/cities_screen.dart';
import 'ui/cities/city_search_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // R12: Arabic UI shows Latin digits.
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
  final prefs = await SharedPreferences.getInstance();
  final dir = await getApplicationSupportDirectory();
  final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
  final repo = WeatherRepository(
    WeatherApi(dio, key: AppConfig.apiKey),
    FileWeatherCache(Directory('${dir.path}/weather_cache')),
  );
  runApp(
    ProviderScope(
      // No automatic retries: failed loads (bad key, quota, offline) wait for
      // the user's retry / pull-to-refresh instead of re-hitting the API.
      retry: (_, _) => null,
      overrides: [
        prefsStoreProvider.overrideWithValue(PrefsStore(prefs)),
        weatherRepositoryProvider.overrideWithValue(repo),
        locationServiceProvider.overrideWithValue(GeolocatorLocationService()),
        textTranslatorProvider.overrideWithValue(MlKitTextTranslator()),
        localeProvider.overrideWith(
          () =>
              LocaleNotifier(WidgetsBinding.instance.platformDispatcher.locale),
        ),
      ],
      child: const HoWeatherApp(),
    ),
  );
}

class HoWeatherApp extends ConsumerWidget {
  const HoWeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en'), Locale('ar')],
      locale: ref.watch(appLocaleProvider),
      themeMode: switch (theme) {
        ThemePref.system => ThemeMode.system,
        ThemePref.light => ThemeMode.light,
        ThemePref.dark => ThemeMode.dark,
      },
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routes: {
        '/cities': (_) => const CitiesScreen(),
        '/search': (_) => const CitySearchScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
      home: const HomeScreen(),
    );
  }
}
