import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howeather/data/location_service.dart';
import 'package:howeather/data/prefs_store.dart';
import 'package:howeather/data/weather_mapper.dart';
import 'package:howeather/data/weather_repository.dart';
import 'package:howeather/domain/models.dart';
import 'package:howeather/l10n/gen/app_localizations.dart';
import 'package:howeather/state/providers.dart';
import 'package:howeather/ui/cities/cities_screen.dart';
import 'package:howeather/ui/cities/city_search_screen.dart';
import 'package:howeather/ui/home/home_screen.dart';
import 'package:howeather/ui/icons/glyphs.dart';
import 'package:howeather/ui/theme.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRepo extends Mock implements WeatherRepository {}

class NoLocation implements LocationService {
  @override
  Future<LocationOutcome> current() async => const LocationDenied();

  @override
  Future<void> openSettings() async {}
}

City mk(String id, String name, {String country = ''}) => City(
  id: id,
  name: name,
  region: '',
  country: country,
  lat: 1,
  lon: 2,
  isCurrentLocation: id == 'loc',
);

final loc = mk('loc', '');
final paris = mk('48.85,2.35', 'Paris', country: 'France');
final cairo = mk('30.04,31.24', 'Cairo', country: 'Egypt');
final khartoum = mk('15.55,32.53', 'Khartoum', country: 'Sudan');

final bundle = mapForecast(
  jsonDecode(File('test/fixtures/forecast_london.json').readAsStringSync())
      as Map<String, dynamic>,
  fetchedAt: DateTime.utc(2026, 11, 9, 17, 40),
);

MockRepo repoWithWeather() {
  final r = MockRepo();
  when(
    () => r.load(
      any(),
      lang: any(named: 'lang'),
      maxAge: any(named: 'maxAge'),
      force: any(named: 'force'),
    ),
  ).thenAnswer((_) async => WeatherResult(bundle));
  return r;
}

late ProviderContainer container;

/// PrefsStore whose city writes fail.
class FailingSaveStore extends PrefsStore {
  FailingSaveStore(super.p);
  @override
  Future<void> saveCities(List<City> c) async =>
      throw const FileSystemException('disk full');
}

/// PrefsStore whose city writes wait for [gate].
class GatedSaveStore extends PrefsStore {
  GatedSaveStore(super.p);
  final gate = Completer<void>();
  @override
  Future<void> saveCities(List<City> c) async {
    await gate.future;
    await super.saveCities(c);
  }
}

/// Pumps a home page with a button that pushes [target] onto the stack.
Future<void> pumpScreen(
  WidgetTester tester, {
  required List<City> saved,
  required MockRepo repo,
  required Widget target,
  Widget? home,
  PrefsStore Function(SharedPreferences)? store,
}) async {
  SharedPreferences.setMockInitialValues({
    if (saved.isNotEmpty)
      'cities': jsonEncode([for (final c in saved) c.toJson()]),
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        prefsStoreProvider.overrideWithValue(
          store?.call(prefs) ?? PrefsStore(prefs),
        ),
        weatherRepositoryProvider.overrideWithValue(repo),
        locationServiceProvider.overrideWithValue(NoLocation()),
        localeProvider.overrideWith(() => LocaleNotifier(const Locale('en'))),
        clockProvider.overrideWithValue(
          () => DateTime.utc(2026, 11, 9, 17, 40),
        ),
      ],
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 900),
          disableAnimations: true,
        ),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('en'), Locale('ar')],
          locale: const Locale('en'),
          theme: buildTheme(Brightness.light),
          routes: {
            '/search': (_) => const CitySearchScreen(),
            '/settings': (_) => const Scaffold(body: Text('settings-route')),
          },
          home:
              home ??
              Builder(
                builder: (context) {
                  container = ProviderScope.containerOf(context);
                  return Scaffold(
                    body: Column(
                      children: [
                        const Text('home-marker'),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => target),
                          ),
                          child: const Text('open'),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (home == null) {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

void stubSearch(MockRepo r, Map<String, List<City>> byQuery) {
  when(() => r.search(any())).thenAnswer((i) async {
    return byQuery[i.positionalArguments[0]] ?? const [];
  });
}

Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
}

Finder findGlyph(Glyph g) =>
    find.byWidgetPredicate((w) => w is GlyphView && w.glyph == g);

void main() {
  setUpAll(() {
    DateFormat.useNativeDigitsByDefaultFor('ar', false);
    registerFallbackValue(paris);
    registerFallbackValue(Duration.zero);
  });

  group('CitiesScreen', () {
    testWidgets('rows show name, subtitle, temperature and loc pin', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        saved: [loc, paris],
        repo: repoWithWeather(),
        target: const CitiesScreen(),
      );
      expect(find.text('My location'), findsOneWidget);
      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('France'), findsOneWidget);
      expect(find.text('${bundle.current.tempC.round()}°'), findsNWidgets(2));
    });

    testWidgets('a failed weather load shows a dash', (tester) async {
      final r = MockRepo();
      when(
        () => r.load(
          any(),
          lang: any(named: 'lang'),
          maxAge: any(named: 'maxAge'),
          force: any(named: 'force'),
        ),
      ).thenThrow(const WeatherApiException(null, 'offline'));
      await pumpScreen(
        tester,
        saved: [paris],
        repo: r,
        target: const CitiesScreen(),
      );
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('tapping a row selects it and pops back', (tester) async {
      await pumpScreen(
        tester,
        saved: [paris, cairo],
        repo: repoWithWeather(),
        target: const CitiesScreen(),
      );
      await tester.tap(find.text('Cairo'));
      await tester.pumpAndSettle();
      expect(container.read(pageIndexProvider), 1);
      expect(find.text('home-marker'), findsOneWidget);
    });

    testWidgets('swipe deletes a city', (tester) async {
      await pumpScreen(
        tester,
        saved: [paris, cairo],
        repo: repoWithWeather(),
        target: const CitiesScreen(),
      );
      await tester.drag(find.text('Cairo'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Cairo'), findsNothing);
      expect(container.read(citiesProvider).value, [paris]);
    });

    testWidgets('failed delete restores the row and shows an error', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        saved: [paris, cairo],
        repo: repoWithWeather(),
        target: const CitiesScreen(),
        store: FailingSaveStore.new,
      );
      await tester.drag(find.text('Cairo'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Cairo'), findsOneWidget);
      expect(find.text("Couldn't load the weather"), findsOneWidget);
      expect(container.read(citiesProvider).value, [paris, cairo]);
    });

    testWidgets('loc row has no dismiss and no drag handle', (tester) async {
      await pumpScreen(
        tester,
        saved: [loc, paris],
        repo: repoWithWeather(),
        target: const CitiesScreen(),
      );
      expect(find.byType(Dismissible), findsOneWidget);
      expect(findGlyph(Glyph.dragHandle), findsOneWidget);
      await tester.drag(find.text('My location'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('My location'), findsOneWidget);
      expect(container.read(citiesProvider).value, [loc, paris]);
    });

    testWidgets('settings action pushes /settings; FAB opens search', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        saved: [paris],
        repo: repoWithWeather(),
        target: const CitiesScreen(),
      );
      await tester.tap(find.byTooltip('Add city'));
      await tester.pumpAndSettle();
      expect(find.byType(CitySearchScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('settings-route'), findsOneWidget);
    });
  });

  group('CitySearchScreen', () {
    testWidgets('debounce cancels stale query: one search, for "khar"', (
      tester,
    ) async {
      final r = repoWithWeather();
      stubSearch(r, {
        'khar': [khartoum],
      });
      await pumpScreen(
        tester,
        saved: [paris],
        repo: r,
        target: const CitySearchScreen(),
      );
      await type(tester, 'kh');
      await tester.pump(const Duration(milliseconds: 100));
      await type(tester, 'khar');
      await tester.pump(const Duration(milliseconds: 349));
      verifyNever(() => r.search(any()));
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pumpAndSettle();
      verify(() => r.search('khar')).called(1);
      verifyNever(() => r.search('kh'));
      expect(find.text('Khartoum, Sudan'), findsOneWidget);
    });

    testWidgets('one character does not search', (tester) async {
      final r = repoWithWeather();
      stubSearch(r, {});
      await pumpScreen(
        tester,
        saved: [paris],
        repo: r,
        target: const CitySearchScreen(),
      );
      await type(tester, 'k');
      await tester.pump(const Duration(seconds: 1));
      verifyNever(() => r.search(any()));
    });

    testWidgets('stale response is ignored', (tester) async {
      final r = repoWithWeather();
      final slow = Completer<List<City>>();
      when(() => r.search('kh')).thenAnswer((_) => slow.future);
      when(() => r.search('khar')).thenAnswer((_) async => [khartoum]);
      await pumpScreen(
        tester,
        saved: [paris],
        repo: r,
        target: const CitySearchScreen(),
      );
      await type(tester, 'kh');
      await tester.pump(const Duration(milliseconds: 400));
      await type(tester, 'khar');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      slow.complete([cairo]);
      await tester.pumpAndSettle();
      expect(find.text('Khartoum, Sudan'), findsOneWidget);
      expect(find.text('Cairo, Egypt'), findsNothing);
    });

    testWidgets('shows progress while searching, then no-results', (
      tester,
    ) async {
      final r = repoWithWeather();
      final pending = Completer<List<City>>();
      when(() => r.search('zzzz')).thenAnswer((_) => pending.future);
      await pumpScreen(
        tester,
        saved: [paris],
        repo: r,
        target: const CitySearchScreen(),
      );
      await type(tester, 'zzzz');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(const []);
      await tester.pumpAndSettle();
      expect(find.text('No cities found'), findsOneWidget);
    });

    testWidgets('search error shows the R9 message', (tester) async {
      final r = repoWithWeather();
      when(() => r.search(any()))
          .thenThrow(const WeatherApiException(null, 'offline'));
      await pumpScreen(
        tester,
        saved: [paris],
        repo: r,
        target: const CitySearchScreen(),
      );
      await type(tester, 'khar');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text("You're offline"), findsOneWidget);
    });

    testWidgets('tapping a result adds it, selects it, pops home', (
      tester,
    ) async {
      final r = repoWithWeather();
      stubSearch(r, {
        'khar': [khartoum],
      });
      await pumpScreen(
        tester,
        saved: [paris, cairo],
        repo: r,
        target: const CitySearchScreen(),
      );
      await type(tester, 'khar');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khartoum, Sudan'));
      await tester.pumpAndSettle();
      expect(container.read(citiesProvider).value, [paris, cairo, khartoum]);
      expect(container.read(pageIndexProvider), 2);
      expect(find.text('home-marker'), findsOneWidget);
    });

    testWidgets('already-saved result shows a check and just pops', (
      tester,
    ) async {
      final r = repoWithWeather();
      stubSearch(r, {
        'pari': [paris],
      });
      await pumpScreen(
        tester,
        saved: [paris, cairo],
        repo: r,
        target: const CitySearchScreen(),
      );
      await type(tester, 'pari');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(findGlyph(Glyph.check), findsOneWidget);
      await tester.tap(find.text('Paris, France'));
      await tester.pumpAndSettle();
      expect(container.read(citiesProvider).value, [paris, cairo]);
      expect(find.text('home-marker'), findsOneWidget);
    });

    testWidgets('leaving search while a pick is saving does not crash', (
      tester,
    ) async {
      final r = repoWithWeather();
      stubSearch(r, {
        'khar': [khartoum],
      });
      late GatedSaveStore gated;
      await pumpScreen(
        tester,
        saved: [paris],
        repo: r,
        target: const CitySearchScreen(),
        store: (p) => gated = GatedSaveStore(p),
      );
      await type(tester, 'khar');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khartoum, Sudan'));
      await tester.pump();
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.byType(CitySearchScreen), findsNothing);
      gated.gate.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(container.read(citiesProvider).value, [paris, khartoum]);
      expect(container.read(pageIndexProvider), 0);
    });

    testWidgets('with 10 cities, tapping a result shows the limit snackbar', (
      tester,
    ) async {
      final ten = [for (var i = 0; i < 10; i++) mk('$i,$i', 'City$i')];
      final r = repoWithWeather();
      stubSearch(r, {
        'khar': [khartoum],
      });
      await pumpScreen(
        tester,
        saved: ten,
        repo: r,
        target: const CitySearchScreen(),
      );
      await type(tester, 'khar');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khartoum, Sudan'));
      await tester.pumpAndSettle();
      expect(find.text('You can save up to 10 cities'), findsOneWidget);
      expect(container.read(citiesProvider).value, ten);
      expect(find.byType(CitySearchScreen), findsOneWidget);
    });
  });

  testWidgets('removing the last city keeps HomeScreen in range', (
    tester,
  ) async {
    final three = [paris, cairo, khartoum];
    await pumpScreen(
      tester,
      saved: three,
      repo: repoWithWeather(),
      target: const SizedBox(),
      home: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return const HomeScreen();
        },
      ),
    );
    container.read(pageIndexProvider.notifier).set(2);
    await tester.pumpAndSettle();
    expect(find.text('Khartoum'), findsOneWidget);

    await container.read(citiesProvider.notifier).remove(khartoum.id);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Cairo'), findsOneWidget);
    expect(container.read(pageIndexProvider), 1);
  });
}
